import json
import os
import unittest

import jose
import jose.compact
import jose.jwk
import jose.jws

HERE = os.path.dirname(os.path.abspath(__file__))


class JoseTests(unittest.TestCase):
    def test_jwk_generate(self):
        jwk = {'alg': 'A128GCM'}
        jose.jwk.generate(jwk)
        k = jwk.pop('k')
        self.assertTrue(k)
        self.assertEqual(jwk, {
            'alg': 'A128GCM', 'kty': 'oct',
            'key_ops': ['encrypt', 'decrypt'], 'use': 'enc'
        })

        self.assertRaises(TypeError, jose.jwk.generate)
        self.assertRaises(TypeError, jose.jwk.generate, None)
        self.assertRaises(TypeError, jose.jwk.generate, b'')
        self.assertRaises(jose.JoseOperationError, jose.jwk.generate, {})

    def test_jwk_allowed(self):
        jwk = {'alg': 'A128GCM'}
        self.assertTrue(jose.jwk.allowed(jwk, op='encrypt'))

    def test_jwk_thumbprint(self):
        jwk = {
            u'kty': u'oct', u'use': u'enc', u'alg': u'A128GCM',
            u'key_ops': [u'encrypt', u'decrypt'],
            u'k': u'cVoUQRUE5rk3V2YbqZG38Q'}
        self.assertEqual(jose.jwk.thumbprint(jwk),
                         'lUPQ1EXWqsVivPRUWgUssyOULBw')

    def test_jws_sign(self):
        jwk = {'alg': 'HS256'}
        jose.jwk.generate(jwk)
        jws = {u'payload': u'egg'}
        sig = {u'protected': {u'header': u'value'}}
        jose.jws.sign(jws, jwk)
        jose.jws.sign(jws, jwk, None)
        jose.jws.sign(jws, jwk, sig)

    def test_compact(self):
        filename = os.path.join(HERE, 'vectors', 'rfc7515_A.1.jwsc')
        with open(filename, 'rb') as f:
            data = f.read()
        j1 = jose.compact.loads(data)
        self.assertIsInstance(j1, dict)
        self.assertEqual(j1, {
            u'signature': u'dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk',
            u'payload': (
                u'eyJpc3MiOiJqb2UiLA0KICJleHAiOjEzMDA4MTkzODAsDQogImh0dHA6L'
                u'y9leGFtcGxlLmNvbS9pc19yb290Ijp0cnVlfQ'),
            u'protected': u'eyJ0eXAiOiJKV1QiLA0KICJhbGciOiJIUzI1NiJ9',
        })
        j2 = jose.compact.loads(jose.compact.dumps(jose.compact.loads(data)))
        self.assertEqual(j1, j2)

        self.assertRaises(TypeError, jose.compact.loads)
        self.assertRaises(TypeError, jose.compact.loads, {})
        self.assertRaises(TypeError, jose.compact.loads, None)
        self.assertRaises(TypeError, jose.compact.loads, object)
        self.assertRaises(TypeError, jose.compact.loads, u'')
        self.assertRaises(jose.JoseOperationError, jose.compact.loads, b'')

        c = jose.compact.dumps(j1)
        self.assertIsInstance(c, bytes)
        self.assertEqual(c, data)

        self.assertRaises(TypeError, jose.compact.dumps)
        self.assertRaises(TypeError, jose.compact.dumps, None)
        self.assertRaises(TypeError, jose.compact.dumps, b'')
        self.assertRaises(TypeError, jose.compact.dumps, u'')
        self.assertRaises(jose.JoseOperationError, jose.compact.dumps, {})


class JoseVectorTests(unittest.TestCase):
    def json_vector(self, name):
        filename = os.path.join(HERE, 'vectors', name)
        with open(filename) as f:
            js = json.load(f)
        self.assertIsInstance(js, dict)
        return js

    def compact_vector(self, name):
        filename = os.path.join(HERE, 'vectors', name)
        with open(filename, 'rb') as f:
            data = f.read()
        js = jose.compact.loads(data)
        self.assertIsInstance(js, dict)
        self.assertEqual(jose.compact.dumps(js), data)
        return js

    def test_jws_rfc7515(self):
        names = ['rfc7515_A.1', 'rfc7515_A.2', 'rfc7515_A.3', 'rfc7515_A.4']
        for name in names:
            jws = self.compact_vector(name + '.jwsc')
            jwk = self.json_vector(name + '.jwk')
            self.assertTrue(jose.jws.verify(jws, jwk), name)
        # 'rfc7515_A.5' not supported
        # 'rfc7515_A.6'
        # 'rfc7515_A.7'
        # 'rfc7515_B'

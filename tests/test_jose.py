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

    def test_get_supported_algorithms(self):
        sup = jose.get_supported_algorithms()
        self.assertEqual(
            set(sup),
            {'jwe_crypters', 'jwe_wrappers', 'jwe_zippers', 'jwk_generators',
             'jwk_hashers', 'jwk_ops', 'jwk_types', 'jws_signers'})
        self.assertEqual(
            sup['jwe_crypters'],
            {'A128CBC-HS256', 'A128GCM', 'A192CBC-HS384', 'A192GCM',
             'A256CBC-HS512',  'A256GCM'}
        )
        self.assertEqual(
            sup['jwe_wrappers'],
            {'A128GCMKW', 'A128KW', 'A192GCMKW', 'A192KW',
             'A256GCMKW', 'A256KW', 'ECDH-ES', 'ECDH-ES+A128KW',
             'ECDH-ES+A192KW', 'ECDH-ES+A256KW', 'PBES2-HS256+A128KW',
             'PBES2-HS384+A192KW', 'PBES2-HS512+A256KW', 'RSA-OAEP',
             'RSA-OAEP-256', 'RSA1_5', 'dir'}
        )
        self.assertEqual(sup['jwe_zippers'], {'DEF'})
        self.assertEqual(sup['jwk_generators'], {'EC', 'oct', 'RSA'})
        self.assertEqual(
            sup['jws_signers'],
            {'ES256', 'ES384', 'ES512', 'HS256', 'HS384', 'HS512', 'PS256',
             'PS384', 'PS512', 'RS256', 'RS384', 'RS512'})
        self.assertEqual(
            sup['jwk_hashers'],
            {'sha1': 20,
             'sha224': 28,
             'sha256': 32,
             'sha384': 48,
             'sha512': 64})
        self.assertEqual(
            sorted(sup['jwk_ops']),
            [('encrypt', 'decrypt', 'enc'),
             ('verify', 'sign', 'sig'),
             ('wrapKey', 'unwrapKey', 'enc')]
        )
        self.assertEqual(
            sup['jwk_types'],
            {
                'EC': {'prv': ['d'],
                       'req': ['crv', 'x', 'y'],
                       'sym': False},
                'RSA': {'prv': ['p', 'd', 'q', 'dp', 'dq', 'qi', 'oth'],
                        'req': ['e', 'n'],
                        'sym': False},
                'oct': {'prv': ['k'],
                        'req': ['k'],
                        'sym': True},
            }
        )

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

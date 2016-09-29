import unittest

import jose


class JoseTests(unittest.TestCase):
    def test_jwk_generate(self):
        jwk = {'alg': 'A128GCM'}
        jose.jwk_generate(jwk)
        k = jwk.pop('k')
        self.assertTrue(k)
        self.assertEqual(jwk, {
            'alg': 'A128GCM', 'kty': 'oct',
            'key_ops': ['encrypt', 'decrypt'], 'use': 'enc'
        })

    def test_jwk_allowed(self):
        jwk = {'alg': 'A128GCM'}
        self.assertTrue(jose.jwk_allowed(jwk, use='enc', op='encrypt'))

    def test_jwk_thumbprint(self):
        jwk = {
            u'kty': u'oct', u'use': u'enc', u'alg': u'A128GCM',
            u'key_ops': [u'encrypt', u'decrypt'],
            u'k': u'cVoUQRUE5rk3V2YbqZG38Q'}
        self.assertEqual(jose.jwk_thumbprint(jwk),
                         'lUPQ1EXWqsVivPRUWgUssyOULBw')

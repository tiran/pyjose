import unittest

import jose


class JoseTests(unittest.TestCase):
    def test_jwk_generate(self):
        j = jose.jwk_generate({'alg': 'A128GCM'})
        self.assertEqual(j['alg'], u'A128GCM')

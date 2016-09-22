import json
import sys
import unittest

from pyjose import Jansson


class JanssonTests(unittest.TestCase):
    def assert_json(self, obj):
        dump = json.dumps(obj)
        jansson = Jansson(obj)
        self.assertEqual(jansson.dumps(), dump)
        self.assertEqual(jansson.dump(), obj)
        # sanity check
        self.assertEqual(json.loads(dump), obj)

    def test_jansson(self):
        self.assert_json({u'foo': u'bar'})
        self.assert_json([True, False, None, 1, 4.5, u'text', [], {}])
        self.assert_json({
            u'true': True,
            u'false': False,
            u'null': None,
            u'int': 1,
            u'real': 4.5,
            u'text': u'text',
            u'array': [],
            u'object': {},
        })
        if sys.version_info.major == 2:
            self.assert_json([long(1)])  # noqa F821

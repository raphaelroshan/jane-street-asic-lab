import unittest

from lab_asm import jump, set_pin, wait, wait_pin


class EncoderTest(unittest.TestCase):
    def test_known_encodings(self):
        self.assertEqual(set_pin(0, 1), 0x04)
        self.assertEqual(wait(2), 0x42)
        self.assertEqual(jump(5), 0x85)
        self.assertEqual(wait_pin(2, 1), 0xD4)

    def test_rejects_values_that_do_not_fit(self):
        with self.assertRaises(ValueError):
            set_pin(8, 1)
        with self.assertRaises(ValueError):
            wait(64)
        with self.assertRaises(TypeError):
            jump(True)


if __name__ == "__main__":
    unittest.main()

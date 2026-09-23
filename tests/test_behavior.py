"""End-to-end checks with disposable homes and a fake Claude executable."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]

class Behavior(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name) / 'home with spaces'
        self.home.mkdir()
        self.base = self.home / 'projects'
        self.base.mkdir()
        self.marker = self.home / 'launched'
        fake = self.home / 'fake-claude'
        fake.write_text('#!/bin/bash\npwd > "$TEST_MARKER"\n')
        fake.chmod(0o755)
        self.env = {k:v for k,v in os.environ.items() if not k.startswith(('CC_PICKER_', 'XDG_'))}
        self.env.update(HOME=str(self.home), CC_PICKER_BASE=str(self.base),
                        CC_PICKER_BIN=str(fake), CC_PICKER_LANG='en',
                        CC_PICKER_NO_PATH='1', CC_PICKER_NO_DEPS='1',
                        TEST_MARKER=str(self.marker))

    def run_picker(self, text):
        r = subprocess.run(['bash', str(ROOT/'cc-picker.sh'), '--shell-mode'],
                           input=text, text=True, capture_output=True, env=self.env, timeout=10)
        self.assertEqual(r.returncode, 0, r.stderr)
        return r

    def test_select_folder_with_spaces(self):
        folder = self.base / 'my project'
        folder.mkdir()
        self.run_picker('1\n')
        self.assertEqual(self.marker.read_text().strip(), str(folder))

    def test_cancel_git_question_creates_nothing(self):
        self.run_picker('1\nnew-project\n')
        self.assertEqual(list(self.base.iterdir()), [])
        self.assertFalse(self.marker.exists())

    def test_confirm_empty_url_creates_folder(self):
        self.run_picker('1\nnew-project\n\n')
        self.assertTrue((self.base/'new-project').is_dir())
        self.assertEqual(self.marker.read_text().strip(), str(self.base/'new-project'))

    def test_control_character_rejected(self):
        self.run_picker('1\nbad\tname\ngood-name\n\n')
        self.assertFalse((self.base/'bad\tname').exists())
        self.assertTrue((self.base/'good-name').is_dir())

    def test_existing_control_character_folder_skipped(self):
        (self.base/'bad\tname').mkdir()
        (self.base/'good').mkdir()
        self.run_picker('1\n')
        self.assertEqual(self.marker.read_text().strip(), str(self.base/'good'))

    def test_failed_clone_does_not_launch(self):
        self.run_picker('1\nclone-failure\n/definitely-missing-cc-picker-repository\n')
        self.assertFalse(self.marker.exists())
        self.assertFalse((self.base/'clone-failure').exists())

    def test_eof_does_not_launch(self):
        self.run_picker('')
        self.assertFalse(self.marker.exists())

    def test_config_is_not_executed_and_environment_wins(self):
        config = self.home/'.config/cc-picker'
        config.mkdir(parents=True)
        config.joinpath('config').write_text('CC_PICKER_BASE=/nonexistent/ignored\nUNKNOWN=$(touch '+str(self.home/'unsafe')+')\n')
        (self.base/'chosen').mkdir()
        self.run_picker('1\n')
        self.assertFalse((self.home/'unsafe').exists())
        self.assertEqual(self.marker.read_text().strip(), str(self.base/'chosen'))

    def test_installer_and_desktop_launch_with_special_path(self):
        from gi.repository import Gio
        special = self.home / 'quote" dollar$ tick` percent% back\\slash'
        special.mkdir()
        self.env['HOME'] = str(special)
        for _ in range(2):
            subprocess.run(['bash', str(ROOT/'install.sh')], env=self.env,
                           check=True, capture_output=True, timeout=10)
        desktop = special/'.local/share/applications/cc-picker.desktop'
        subprocess.run(['desktop-file-validate', str(desktop)], check=True, capture_output=True)
        binary = special/'.local/bin/cc-picker'
        binary.write_text('#!/bin/bash\nprintf done > "'+str(self.marker)+'"\n')
        app = Gio.DesktopAppInfo.new_from_filename(str(desktop))
        self.assertIsNotNone(app)
        self.assertTrue(app.launch([], None))
        import time
        for _ in range(50):
            if self.marker.exists(): break
            time.sleep(.02)
        self.assertEqual(self.marker.read_text(), 'done')

if __name__ == '__main__':
    unittest.main()

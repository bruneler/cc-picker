"""End-to-end checks with disposable homes and a fake Claude executable."""
import os
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]

# Answers come one per call from $TEST_ANSWERS; "__cancel__" presses Cancel.
# Error and info boxes are only logged.
FAKE_DIALOG = r'''#!/bin/bash
printf '%s\n' "$*" >> "$TEST_DIALOG_LOG"
case " $* " in *" --error "*|*" --info "*) exit 0 ;; esac
answer="$(head -n1 "$TEST_ANSWERS")"
sed -i 1d "$TEST_ANSWERS"
[ "$answer" = "__cancel__" ] && exit 1
case " $* " in *" --question "*) exit 0 ;; esac
printf '%s\n' "$answer"
'''

class Behavior(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name) / 'home with spaces'
        self.home.mkdir()
        self.base = self.home / 'projects'
        self.base.mkdir()
        self.marker = self.home / 'launched'
        self.args = self.home / 'claude-args'
        fake = self.home / 'fake-claude'
        fake.write_text('#!/bin/bash\npwd > "$TEST_MARKER"\nprintf "%s\\n" "$@" > "$TEST_ARGS"\n')
        fake.chmod(0o755)
        # fake dialog tool and terminal for the window mode
        self.bin = self.home / 'bin'
        self.bin.mkdir()
        self.answers = self.home / 'answers'
        self.dialog_log = self.home / 'dialog-log'
        self.write_tool('zenity', FAKE_DIALOG)
        self.write_tool('xterm', '#!/bin/bash\n[ "$1" = -e ] && shift\nexec "$@"\n')
        self.env = {k:v for k,v in os.environ.items() if not k.startswith(('CC_PICKER_', 'XDG_'))}
        self.env.update(HOME=str(self.home), CC_PICKER_BASE=str(self.base),
                        CC_PICKER_BIN=str(fake), CC_PICKER_LANG='en',
                        CC_PICKER_NO_PATH='1', CC_PICKER_NO_DEPS='1',
                        CC_PICKER_SHELL='/bin/true', CC_PICKER_FZF='0',
                        # never open real windows: no dialog tool, fake xterm
                        CC_PICKER_DIALOG='none', CC_PICKER_TERMINAL='xterm',
                        PATH=str(self.bin) + ':' + os.environ['PATH'],
                        TEST_MARKER=str(self.marker), TEST_ARGS=str(self.args),
                        TEST_ANSWERS=str(self.answers), TEST_DIALOG_LOG=str(self.dialog_log))

    def write_tool(self, name, text):
        tool = self.bin / name
        tool.write_text(text)
        tool.chmod(0o755)

    def run_cmd(self, *args, text='', check=True):
        r = subprocess.run(['bash', str(ROOT/'cc-picker.sh'), *args],
                           input=text, text=True, capture_output=True, env=self.env, timeout=20)
        if check:
            self.assertEqual(r.returncode, 0, r.stderr)
        return r

    def run_gui(self, *answers):
        self.answers.write_text(''.join(a + '\n' for a in answers))
        self.env['CC_PICKER_DIALOG'] = 'zenity'
        return self.run_cmd()

    def launched(self):
        return self.marker.read_text().strip() if self.marker.exists() else None

    def claude_args(self):
        return self.args.read_text().split() if self.args.exists() else None

    def add_session(self, project):
        encoded = re.sub('[^A-Za-z0-9]', '-', str(project))
        sessions = self.home / '.claude/projects' / encoded
        sessions.mkdir(parents=True)
        (sessions / 'abc.jsonl').write_text('{}\n')

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
        r = self.run_picker('1\nclone-failure\n/definitely-missing-cc-picker-repository\n')
        self.assertIn('git clone failed: /definitely-missing-cc-picker-repository', r.stderr)
        self.assertFalse(self.marker.exists())
        self.assertFalse((self.base/'clone-failure').exists())

    def test_option_like_clone_url_is_kept_literally(self):
        # e.g. "-n" must reach git as a URL, not vanish and create an empty folder
        r = self.run_picker('1\nx\n-n\n')
        self.assertIn('git clone failed: -n', r.stderr)
        self.assertFalse((self.base/'x').exists())
        self.assertFalse(self.marker.exists())

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

    # These payloads must remain data across argv, bash -c and state files.
    # If evaluated, the substitutions create a marker inside the disposable home.
    def security_name(self):
        self.env['TEST_SENTINEL'] = str(Path(self.temp.name) / 'unexpected-execution')
        return 'project $(touch${IFS}$TEST_SENTINEL) `touch${IFS}$TEST_SENTINEL` ;& \'" $ \\ end'

    def assert_no_execution(self):
        self.assertFalse(Path(self.env['TEST_SENTINEL']).exists())

    def test_security_create_and_recent_preserve_metacharacters(self):
        name = self.security_name()
        self.run_picker('1\n' + name + '\n\n')
        self.assertTrue((self.base / name).is_dir())
        self.assertEqual(self.launched(), str(self.base / name))
        self.marker.unlink()
        self.run_cmd('--shell-mode', '-')
        self.assertEqual(self.launched(), str(self.base / name))
        self.assert_no_execution()

    def test_security_all_terminals_preserve_command_and_directory(self):
        name = self.security_name()
        project = self.base / name
        project.mkdir()
        # Executable paths also exercise Bash's ANSI-C quoting for controls.
        binary = self.home / ('claude ' + name + '\t\n\x1b')
        shutil.copy(self.env['CC_PICKER_BIN'], binary)
        shell = self.home / ('shell ' + name + '\t\n\x1b')
        shutil.copy('/bin/true', shell)
        self.env.update(CC_PICKER_BIN=str(binary), CC_PICKER_SHELL=str(shell))
        log = self.home / 'terminal-argv'
        self.env['TEST_TERMINAL_LOG'] = str(log)
        terminal = '#!' + sys.executable + '\n' + '''import json, os, sys
args = sys.argv[1:]
with open(os.environ['TEST_TERMINAL_LOG'], 'w') as f:
    json.dump(args, f)
if args[0].startswith('--working-directory='):
    os.chdir(args.pop(0).split('=', 1)[1])
elif args[0] in ('--workdir', '--working-directory', '--directory'):
    os.chdir(args[1]); del args[:2]
if args[0] in ('--', '-e', '-x'):
    args.pop(0)
os.execvp(args[0], args)
'''
        prefixes = {
            'gnome-terminal': ['--working-directory=' + str(project), '--'],
            'konsole': ['--workdir', str(project), '-e'],
            'xfce4-terminal': ['--working-directory=' + str(project), '-x'],
            'alacritty': ['--working-directory', str(project), '-e'],
            'kitty': ['--directory', str(project)],
            'xterm': ['-e'],
        }
        for tool, prefix in prefixes.items():
            with self.subTest(terminal=tool):
                self.write_tool(tool, terminal)
                self.env['CC_PICKER_TERMINAL'] = tool
                self.run_gui('p0')
                self.assertEqual(self.launched(), str(project))
                argv = json.loads(log.read_text())
                self.assertEqual(argv[:-1], prefix + ['bash', '-c'])
                self.assertEqual(self.claude_args(), [])
                self.assert_no_execution()
                self.marker.unlink()

    def test_security_clone_passes_literal_url_after_option_separator(self):
        name = self.security_name()
        log = self.home / 'clone-argv'
        self.env['TEST_CLONE_LOG'] = str(log)
        self.write_tool('git', '#!/bin/bash\n'
                        'if [ "$1" = clone ]; then\n'
                        '  printf "%s\\0" "$@" > "$TEST_CLONE_LOG"\n'
                        '  exit 1\nfi\nexit 0\n')
        for url in (name + '\t\x1b', '--upload-pack=' + name):
            with self.subTest(url=url):
                self.run_picker('1\n' + name + '\n' + url + '\n')
                self.assertEqual(log.read_bytes().split(b'\0')[:-1],
                                 [s.encode() for s in ('clone', '--', url, str(self.base / name))])
                self.assertFalse((self.base / name).exists())
                self.assertIsNone(self.launched())
                self.assert_no_execution()

    def test_security_rename_archive_restore_preserve_paths_and_contents(self):
        name = self.security_name()
        original = self.base / name
        original.mkdir()
        (original / 'keep.txt').write_text('keep me')
        self.run_cmd('--shell-mode', name)
        renamed = self.base / ('renamed ' + name)
        self.run_gui('manage', 'p0', 'rename', renamed.name, '__cancel__')
        self.assertFalse(original.exists())
        self.run_cmd('--shell-mode', '-')
        self.assertEqual(self.launched(), str(renamed))
        self.run_gui('manage', 'p0', 'archive', 'yes', '__cancel__')
        self.assertFalse(renamed.exists())
        self.assertEqual((self.base / '.archive' / renamed.name / 'keep.txt').read_text(), 'keep me')
        self.run_gui('manage', 'restore', 'a0', '__cancel__')
        self.assertEqual((renamed / 'keep.txt').read_text(), 'keep me')
        self.assert_no_execution()

    def test_security_known_config_values_are_literal(self):
        name = self.security_name()
        base = self.home / name
        (base / 'chosen').mkdir(parents=True)
        binary = self.home / ('bin ' + name)
        shutil.copy(self.env['CC_PICKER_BIN'], binary)
        config = self.home / '.config/cc-picker/config'
        config.parent.mkdir(parents=True)
        config.write_text('CC_PICKER_BASE=' + str(base) + '\n'
                          'CC_PICKER_BIN=' + str(binary) + '\n'
                          'CC_PICKER_SESSION=' + name + '\n')
        del self.env['CC_PICKER_BASE'], self.env['CC_PICKER_BIN']
        self.run_cmd('--shell-mode', 'chosen')
        self.assertEqual(self.launched(), str(base / 'chosen'))
        self.assert_no_execution()

    def test_security_control_characters_rejected_and_existing_paths_skipped(self):
        for control in ('\t', '\r', '\x1b', '\x7f'):
            with self.subTest(control=repr(control)):
                self.run_picker('1\nbad' + control + 'name\n')
                self.assertEqual(list(self.base.iterdir()), [])
                self.assertIsNone(self.launched())
        for control in ('\t', '\r', '\n', '\x1b', '\x7f'):
            (self.base / ('bad' + control + 'name')).mkdir()
        (self.base / 'good').mkdir()
        self.run_picker('1\n')
        self.assertEqual(self.launched(), str(self.base / 'good'))

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
        template = special/'.config/cc-picker/templates/standard'
        self.assertTrue((template/'CLAUDE.md').is_file())
        self.assertTrue((template/'.gitignore').is_file())
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

    # --- 0.3: sessions ---

    def test_no_session_question_without_sessions(self):
        (self.base/'alpha').mkdir()
        self.run_picker('1\n')
        self.assertEqual(self.claude_args(), [])

    def test_session_question_continue(self):
        folder = self.base/'alpha'
        folder.mkdir()
        self.add_session(folder)
        self.run_picker('1\n2\n')
        self.assertEqual(self.launched(), str(folder))
        self.assertEqual(self.claude_args(), ['--continue'])

    def test_session_question_resume(self):
        folder = self.base/'alpha'
        folder.mkdir()
        self.add_session(folder)
        self.run_picker('1\n3\n')
        self.assertEqual(self.claude_args(), ['--resume'])

    def test_session_setting_skips_question(self):
        folder = self.base/'alpha'
        folder.mkdir()
        self.add_session(folder)
        self.env['CC_PICKER_SESSION'] = 'new'
        self.run_picker('1\n')
        self.assertEqual(self.claude_args(), [])

    # --- 0.3: search in the terminal menu ---

    def test_text_filters_menu(self):
        for name in ('alpha', 'beta', 'gamma'):
            (self.base/name).mkdir()
        self.run_picker('gam\n')
        self.assertEqual(self.launched(), str(self.base/'gamma'))

    def test_text_with_several_matches_narrows_menu(self):
        for name in ('app-one', 'app-two', 'other'):
            (self.base/name).mkdir()
        self.run_picker('app\n2\n')
        self.assertEqual(self.launched(), str(self.base/'app-two'))

    # --- 0.3: command line ---

    def test_start_by_name(self):
        (self.base/'alpha').mkdir()
        (self.base/'beta').mkdir()
        self.run_cmd('beta')
        self.assertEqual(self.launched(), str(self.base/'beta'))

    def test_start_by_unique_prefix_and_continue_flag(self):
        (self.base/'my-webapp').mkdir()
        (self.base/'notes').mkdir()
        self.run_cmd('--continue', 'my')
        self.assertEqual(self.launched(), str(self.base/'my-webapp'))
        self.assertEqual(self.claude_args(), [])  # no session yet: new one
        self.add_session(self.base/'my-webapp')
        self.run_cmd('-c', 'my')
        self.assertEqual(self.claude_args(), ['--continue'])

    def test_start_unknown_or_ambiguous_name_fails(self):
        (self.base/'app-one').mkdir()
        (self.base/'app-two').mkdir()
        r = self.run_cmd('nope', check=False)
        self.assertEqual(r.returncode, 1)
        self.assertIn('nope', r.stderr)
        r = self.run_cmd('app', check=False)
        self.assertEqual(r.returncode, 1)
        self.assertIn('app-one', r.stderr)
        self.assertIsNone(self.launched())

    def test_dash_starts_last_project(self):
        for name in ('alpha', 'beta'):
            (self.base/name).mkdir()
        self.run_cmd('beta')
        self.run_cmd('alpha')
        self.marker.unlink()
        self.run_cmd('-')
        self.assertEqual(self.launched(), str(self.base/'alpha'))

    def test_legacy_recent_file_is_read(self):
        (self.base/'alpha').mkdir()
        (self.base/'zulu').mkdir()
        state = self.home/'.local/state/cc-picker'
        state.mkdir(parents=True)
        (state/'recent').write_text('1700000000 zulu\n')
        self.run_cmd('-')
        self.assertEqual(self.launched(), str(self.base/'zulu'))

    # --- 0.3: several projects folders, pinning ---

    def test_several_projects_folders(self):
        extra = self.home/'code'
        (extra/'tool').mkdir(parents=True)
        (self.base/'alpha').mkdir()
        self.env['CC_PICKER_BASE'] = str(self.base) + ':' + str(extra)
        self.run_picker('2\n')
        self.assertEqual(self.launched(), str(extra/'tool'))
        self.run_cmd('code/tool')
        self.assertEqual(self.launched(), str(extra/'tool'))

    def test_pinned_project_listed_first(self):
        for name in ('alpha', 'zulu'):
            (self.base/name).mkdir()
        state = self.home/'.local/state/cc-picker'
        state.mkdir(parents=True)
        (state/'pinned').write_text(str(self.base/'zulu') + '\n')
        self.run_picker('1\n')
        self.assertEqual(self.launched(), str(self.base/'zulu'))

    def test_git_status_shown_in_menu(self):
        folder = self.base/'repo'
        folder.mkdir()
        subprocess.run(['git', 'init', '-q', '-b', 'trunk', str(folder)], check=True)
        (folder/'new.txt').write_text('x')
        r = self.run_picker('')
        self.assertIn('trunk · 1 changed', r.stderr)

    # --- 0.3: templates and clone shorthand ---

    def test_template_is_applied(self):
        template = self.home/'.config/cc-picker/templates/standard'
        template.mkdir(parents=True)
        (template/'CLAUDE.md').write_text('# {{PROJECT_NAME}} & more\n')
        self.run_picker('1\nmy-app\n\n2\n')
        project = self.base/'my-app'
        self.assertEqual((project/'CLAUDE.md').read_text(), '# my-app & more\n')
        self.assertTrue((project/'.git').is_dir())
        self.assertEqual(self.launched(), str(project))

    def test_template_question_empty_folder(self):
        (self.home/'.config/cc-picker/templates/standard').mkdir(parents=True)
        self.run_picker('1\nplain\n\n1\n')
        self.assertEqual(list((self.base/'plain').iterdir()), [])

    def test_existing_name_is_rejected(self):
        (self.base/'taken').mkdir()
        self.run_picker('2\ntaken\nfree\n\n')
        self.assertTrue((self.base/'free').is_dir())
        self.assertEqual(self.launched(), str(self.base/'free'))

    def test_github_shorthand_is_expanded(self):
        log = self.home/'git-log'
        self.write_tool('git', '#!/bin/bash\nprintf "%s " "$@" >> "' + str(log) + '"\nexit 1\n')
        self.run_picker('1\ncloned\nsomeone/some.repo\n')
        self.assertIn('https://github.com/someone/some.repo.git', log.read_text())
        self.assertIsNone(self.launched())

    # --- 0.3: managing projects ---

    def test_rename_updates_recent_list(self):
        (self.base/'old').mkdir()
        self.run_cmd('old')
        # menu: 1 old, 2 new, 3 manage → project 1 → action "Rename"
        actions = self.manage_actions()
        self.run_picker('3\n1\n%d\nrenamed\n' % (actions.index('Rename') + 1))
        self.assertFalse((self.base/'old').exists())
        self.assertTrue((self.base/'renamed').is_dir())
        self.marker.unlink()
        self.run_cmd('-')
        self.assertEqual(self.launched(), str(self.base/'renamed'))

    def test_archive_and_restore(self):
        (self.base/'keep').mkdir()
        (self.base/'old').mkdir()
        actions = self.manage_actions()
        # menu: 1 keep, 2 old, 3 new, 4 manage → project 2 → "Archive" → confirm
        self.run_picker('4\n2\n%d\ny\n' % (actions.index('Archive') + 1))
        self.assertFalse((self.base/'old').exists())
        self.assertTrue((self.base/'.archive/old').is_dir())
        # menu: 1 keep, 2 new, 3 manage → 2 = restore → archived project 1
        self.run_picker('3\n2\n1\n')
        self.assertTrue((self.base/'old').is_dir())

    def test_pin_from_manage_menu(self):
        for name in ('alpha', 'zulu'):
            (self.base/name).mkdir()
        actions = self.manage_actions()
        self.run_picker('4\n2\n%d\n' % (actions.index('Pin (always listed first)') + 1))
        self.run_picker('1\n')
        self.assertEqual(self.launched(), str(self.base/'zulu'))

    def manage_actions(self):
        actions = []
        if shutil.which('xdg-open'): actions.append('Open in file manager')
        if any(shutil.which(e) for e in ('code', 'codium', 'zed', 'subl')): actions.append('editor')
        return actions + ['Pin (always listed first)', 'Rename', 'Archive']

    # --- 0.3: window mode with a fake dialog tool ---

    def test_gui_start_uses_hidden_key(self):
        (self.base/'alpha').mkdir()
        (self.base/'beta').mkdir()
        self.run_gui('p1')
        self.assertEqual(self.launched(), str(self.base/'beta'))
        self.assertIn('--hide-column=1', self.dialog_log.read_text())

    def test_gui_session_choice(self):
        folder = self.base/'alpha'
        folder.mkdir()
        self.add_session(folder)
        self.run_gui('p0', 'resume')
        self.assertEqual(self.claude_args(), ['--resume'])

    def test_gui_cancel_starts_nothing(self):
        (self.base/'alpha').mkdir()
        self.run_gui('__cancel__')
        self.assertIsNone(self.launched())

    def test_gui_new_project_with_template(self):
        template = self.home/'.config/cc-picker/templates/standard'
        template.mkdir(parents=True)
        (template/'README.md').write_text('{{PROJECT_NAME}}')
        self.run_gui('new', 'fresh', '', 't0')
        self.assertEqual((self.base/'fresh/README.md').read_text(), 'fresh')
        self.assertEqual(self.launched(), str(self.base/'fresh'))

    def test_gui_failed_clone_shows_error(self):
        # answers: list, name, URL, the busy indicator, then cancel the list
        self.run_gui('new', 'broken', '/definitely-missing-cc-picker-repository',
                     'busy', '__cancel__')
        self.assertIsNone(self.launched())
        self.assertFalse((self.base/'broken').exists())
        error = [l for l in self.dialog_log.read_text().splitlines() if '--error' in l]
        self.assertEqual(len(error), 1)
        self.assertIn('git clone failed: /definitely-missing-cc-picker-repository', error[0])

    def test_gui_rename_then_start(self):
        (self.base/'alpha').mkdir()
        self.run_gui('manage', 'p0', 'rename', 'omega', 'p0')
        self.assertEqual(self.launched(), str(self.base/'omega'))

    def test_gui_search(self):
        for i in range(9):
            (self.base/('project-%d' % i)).mkdir()
        (self.base/'special').mkdir()
        self.run_gui('search', 'spec', 'p9')
        self.assertEqual(self.launched(), str(self.base/'special'))
        self.assertIn('Show all projects', self.dialog_log.read_text())

    # --- 0.3: self-update ---

    def make_release(self, version):
        repo = self.home/'upstream'
        repo.mkdir()
        for name in ('install.sh', 'cc-picker.svg'):
            shutil.copy(ROOT/name, repo/name)
        shutil.copytree(ROOT/'templates', repo/'templates')
        script = (ROOT/'cc-picker.sh').read_text()
        script = re.sub(r'^VERSION=".*"$', 'VERSION="%s"' % version, script, count=1, flags=re.M)
        (repo/'cc-picker.sh').write_text(script)
        git = ['git', '-C', str(repo), '-c', 'user.name=t', '-c', 'user.email=t@example.org']
        subprocess.run(git[:3] + ['init', '-q'], check=True)
        subprocess.run(git + ['add', '.'], check=True)
        subprocess.run(git + ['commit', '-qm', 'release'], check=True)
        subprocess.run(git + ['tag', 'v' + version], check=True)
        self.env['CC_PICKER_UPDATE_REPO'] = str(repo)

    def test_update_installs_newer_version(self):
        self.make_release('9.9.9')
        self.run_cmd('--update')
        installed = self.home/'.local/bin/cc-picker'
        self.assertIn('VERSION="9.9.9"', installed.read_text())

    def test_update_when_current(self):
        version = re.search(r'^VERSION="(.*)"$', (ROOT/'cc-picker.sh').read_text(), re.M).group(1)
        self.make_release(version)
        r = self.run_cmd('--update')
        self.assertIn('up to date', r.stdout)
        self.assertFalse((self.home/'.local/bin/cc-picker').exists())

if __name__ == '__main__':
    unittest.main()

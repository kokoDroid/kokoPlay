#!/usr/bin/python3
"""
Yafti GTK - A simple GTK GUI for running scripts from yafti.yml
"""

import json
import os
import subprocess
import sys
import threading
from pathlib import Path

import gi
import yaml

gi.require_version('Gtk', '4.0')
from gi.repository import GLib, Gtk

# Constants
APP_ID = 'io.github.ublue_os.yafti_gtk'
APP_TITLE = 'KokoPlay Configuration'
DEFAULT_WINDOW_WIDTH = 800
DEFAULT_WINDOW_HEIGHT = 600
STATUS_TIMEOUT_SECONDS = 3
ACTION_DIALOG_WIDTH = 420
AUTOSTART_DESKTOP_FILENAME = f"{APP_ID}.desktop"
AUTOSTART_DIR = Path.home() / '.config' / 'autostart'
AUTOSTART_STATE_DIR = Path.home() / '.config' / 'yafti-gtk'
AUTOSTART_STATE_FILE = AUTOSTART_STATE_DIR / 'autostart_state.json'


def set_widget_margins(widget, top=10, bottom=10, start=10, end=10):
    """Apply consistent margins to a widget."""
    widget.set_margin_top(top)
    widget.set_margin_bottom(bottom)
    widget.set_margin_start(start)
    widget.set_margin_end(end)


def clear_container(container):
    """Remove all children from a container widget."""
    while container.get_first_child() is not None:
        container.remove(container.get_first_child())


def show_error_dialog(parent, title, message):
    """Display an error dialog with the given title and message."""
    dialog = Gtk.MessageDialog(
        transient_for=parent,
        message_type=Gtk.MessageType.ERROR,
        buttons=Gtk.ButtonsType.OK,
        text=title
    )
    dialog.format_secondary_text(message)
    dialog.run()
    dialog.destroy()


def initialize_gtk():
    """Initialize GTK and application metadata."""
    GLib.set_prgname(APP_ID)
    Gtk.init()

    try:
        Gtk.Window.set_default_icon_name(APP_ID)
    except Exception as e:
        print(f"Warning: Could not set app icon: {e}")


def build_terminal_command(script):
    """Return the default terminal launcher command."""
    return [
        "xdg-terminal-exec",
        f"--app-id={APP_ID}",
        f"--title={APP_TITLE}",
        "--",
        "bash",
        "--noprofile",
        "--norc",
        "-lc",
        script,
    ]


def build_headless_command(script):
    """Return the non-interactive command used for status checks."""
    return [
        "bash",
        "--noprofile",
        "--norc",
        "-lc",
        script,
    ]


def escape_markup(text):
    """Escape text before using it in a GTK markup label."""
    return GLib.markup_escape_text(text or "")


class YaftiGTK(Gtk.Window):
    def __init__(self, config_file='yafti.yml'):
        super().__init__(title=APP_TITLE)
        self.set_default_size(DEFAULT_WINDOW_WIDTH, DEFAULT_WINDOW_HEIGHT)
        self.active_dialog_state = None

        # Load YAML configuration
        self.config_file = config_file
        self.config = self.load_config(config_file)
        self.screens = self.config.get('screens', [])
        self.actions_index = self._build_actions_index()

        # Create main container
        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        self.set_child(vbox)

        # Search bar at the top
        search_entry = Gtk.SearchEntry()
        search_entry.set_placeholder_text("Search Apps and Actions")
        set_widget_margins(search_entry, 10, 10, 10, 10)
        search_entry.connect("search-changed", self.on_search_changed)
        vbox.append(search_entry)

        self.autostart_checkbox = self.build_autostart_checkbox()
        vbox.append(self.autostart_checkbox)

        # Notebook (tabs) directly below search
        self.notebook = Gtk.Notebook()
        self.notebook.set_scrollable(True)

        # Add tabs for each screen from YAML
        for screen in self.screens:
            page = self.create_screen_page(screen)
            label = Gtk.Label(label=screen.get('title', 'Tab'))
            self.notebook.append_page(page, label)

        # Stack to switch between notebook and search results
        self.content_stack = Gtk.Stack()
        self.content_stack.set_transition_type(Gtk.StackTransitionType.CROSSFADE)
        self.content_stack.set_transition_duration(150)

        # Add notebook to stack
        self.content_stack.add_named(self.notebook, "tabs")

        # Search results page
        search_scrolled = Gtk.ScrolledWindow()
        search_scrolled.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)
        results_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        results_box.set_vexpand(True)
        set_widget_margins(results_box, 10, 10, 10, 10)
        self.search_results_box = results_box
        search_scrolled.set_child(results_box)
        self.content_stack.add_named(search_scrolled, "search")

        # Start with tabs visible
        self.content_stack.set_visible_child_name("tabs")

        vbox.append(self.content_stack)

        focus_controller = Gtk.EventControllerFocus.new()
        focus_controller.connect("enter", self.on_window_focus_in)

    def load_config(self, config_file):
        """Load and parse the YAML configuration file."""
        try:
            with open(config_file, 'r') as f:
                return yaml.safe_load(f) or {}
        except FileNotFoundError:
            show_error_dialog(
                self,
                "Configuration file not found",
                f"Could not find {config_file} in the current directory."
            )
            sys.exit(1)
        except yaml.YAMLError as e:
            show_error_dialog(self, "YAML parsing error", str(e))
            sys.exit(1)

    def create_screen_page(self, screen):
        """Create a page for a screen with all its actions."""
        scrolled = Gtk.ScrolledWindow()
        scrolled.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)

        page_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        set_widget_margins(page_box, 10, 10, 10, 10)

        for action in screen.get('actions', []):
            action_box = self.create_action_item(action)
            page_box.append(action_box)

        scrolled.set_child(page_box)
        return scrolled

    def create_action_item(self, action):
        """Create a clickable action item."""
        button = Gtk.Button()
        button.set_hexpand(True)
        button.set_halign(Gtk.Align.FILL)

        button_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        set_widget_margins(button_box, 8, 8, 8, 8)

        text_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)

        title_label = Gtk.Label()
        title_label.set_markup(f"<b>{escape_markup(action.get('title', 'Action'))}</b>")
        title_label.set_xalign(0)
        text_box.append(title_label)

        if action.get('description'):
            desc_label = Gtk.Label(label=action['description'])
            desc_label.set_xalign(0)
            desc_label.set_wrap(True)
            desc_label.set_max_width_chars(60)
            desc_label.get_style_context().add_class('dim-label')
            text_box.append(desc_label)

        button_box.append(text_box)
        button.set_child(button_box)
        button.connect("clicked", self.on_action_clicked, action)

        frame = Gtk.Frame()
        frame.set_child(button)

        return frame

    def _build_actions_index(self):
        """Flatten actions for search lookup."""
        index = []
        for screen in self.screens or []:
            for action in screen.get('actions', []):
                index.append({'action': action})
        return index

    def get_action_options(self, action):
        """Return explicit modal options from the config."""
        options = action.get('options')
        if isinstance(options, list) and options:
            return options

        return []

    def build_autostart_checkbox(self):
        """Build the autostart checkbox UI and initialize its state."""
        checkbox = Gtk.CheckButton(label="Start KokoPlay Configuration at login")
        enabled = self.is_autostart_enabled()
        checkbox.set_active(enabled)

        if enabled and not self.get_autostart_desktop_path().exists():
            try:
                self.enable_autostart()
            except RuntimeError:
                pass

        checkbox.connect("toggled", self.on_autostart_toggled)
        set_widget_margins(checkbox, top=0, bottom=10, start=10, end=10)
        return checkbox

    def get_autostart_desktop_path(self):
        """Return the autostart desktop file path."""
        return AUTOSTART_DIR / AUTOSTART_DESKTOP_FILENAME

    def get_autostart_exec(self):
        """Return the Exec command used by the autostart desktop file."""
        script_path = os.path.abspath(__file__)
        return f"{sys.executable} {script_path} {self.config_file}"

    def get_autostart_desktop_content(self):
        """Return the desktop entry content for autostart."""
        return """[Desktop Entry]
Type=Application
Name=KokoPlay Configuration
Exec=%s
X-GNOME-Autostart-enabled=true
NoDisplay=false
""" % self.get_autostart_exec()

    def load_autostart_state(self):
        """Read the user's explicit autostart preference state."""
        if not AUTOSTART_STATE_FILE.exists():
            return {}

        try:
            with AUTOSTART_STATE_FILE.open('r', encoding='utf-8') as f:
                return json.load(f)
        except Exception:
            return {}

    def save_autostart_state(self, state):
        """Persist the user's autostart preference state."""
        try:
            AUTOSTART_STATE_DIR.mkdir(parents=True, exist_ok=True)
            with AUTOSTART_STATE_FILE.open('w', encoding='utf-8') as f:
                json.dump(state, f)
        except Exception as e:
            raise RuntimeError(f"Could not save autostart preferences: {e}")

    def remove_autostart_state(self):
        """Delete the persisted autostart preference state."""
        try:
            if AUTOSTART_STATE_FILE.exists():
                AUTOSTART_STATE_FILE.unlink()
        except Exception as e:
            raise RuntimeError(f"Could not remove autostart preferences: {e}")

    def user_cleared_autostart(self):
        """Return True if the user explicitly disabled autostart."""
        state = self.load_autostart_state()
        return bool(state.get('user_disabled', False))

    def is_autostart_enabled(self):
        """Return True when autostart should be enabled by default or via existing desktop file."""
        desktop_path = self.get_autostart_desktop_path()
        if desktop_path.exists():
            try:
                with desktop_path.open('r', encoding='utf-8') as f:
                    for line in f:
                        if line.startswith('Exec='):
                            return self.get_autostart_exec() in line
            except Exception:
                pass

        if self.user_cleared_autostart():
            return False

        return True

    def enable_autostart(self):
        """Write the autostart desktop file."""
        try:
            AUTOSTART_DIR.mkdir(parents=True, exist_ok=True)
            desktop_path = self.get_autostart_desktop_path()
            with desktop_path.open('w', encoding='utf-8') as f:
                f.write(self.get_autostart_desktop_content())
            self.remove_autostart_state()
        except Exception as e:
            raise RuntimeError(f"Could not enable autostart: {e}")

    def disable_autostart(self):
        """Remove the autostart desktop file."""
        desktop_path = self.get_autostart_desktop_path()
        try:
            if desktop_path.exists():
                desktop_path.unlink()
            self.save_autostart_state({'user_disabled': True})
        except Exception as e:
            raise RuntimeError(f"Could not disable autostart: {e}")

    def on_autostart_toggled(self, checkbox):
        """Handle autostart checkbox toggling."""
        try:
            if checkbox.get_active():
                self.enable_autostart()
            else:
                self.disable_autostart()
        except RuntimeError as e:
            show_error_dialog(self, "Autostart error", str(e))
            checkbox.set_active(not checkbox.get_active())

    def action_uses_modal(self, action):
        """Return True when the action should open the management modal."""
        if self.get_action_options(action):
            return True
        return bool((action.get('status_script') or "").strip())

    def on_search_changed(self, entry):
        query = entry.get_text().strip()
        if not query:
            clear_container(self.search_results_box)
            self.content_stack.set_visible_child_name("tabs")
            return

        lowered = query.lower()
        matches = []
        for item in self.actions_index:
            action = item['action']
            title = action.get('title', '')
            desc = action.get('description', '')
            if lowered in title.lower() or lowered in desc.lower():
                matches.append(item)

        clear_container(self.search_results_box)

        header = Gtk.Label()
        header.set_markup("<b>Search results</b>")
        header.set_xalign(0)
        self.search_results_box.append(header)

        if matches:
            for item in matches:
                self.search_results_box.append(self.create_action_item(item['action']))
        else:
            empty = Gtk.Label(label="No matches found")
            empty.set_xalign(0)
            self.search_results_box.append(empty)

        self.search_results_box.set_visible(True)
        self.content_stack.set_visible_child_name("search")

    def on_action_clicked(self, _button, action):
        """Open a management modal or run the action directly."""
        if not self.action_uses_modal(action):
            script = (action.get('script') or "").strip()
            if not script:
                return

            error_message = self.launch_terminal(script)
            if error_message is None:
                return

            show_error_dialog(
                self,
                "No terminal available",
                "Could not open a terminal automatically.\n\n"
                + error_message
                + "\n\nYou can also run the following command manually:\n\n"
                + script
            )
            return

        dialog = Gtk.Dialog(title=action.get('title', 'Action'), transient_for=self)
        dialog.set_modal(True)
        dialog.set_destroy_with_parent(True)
        dialog.set_default_size(ACTION_DIALOG_WIDTH, -1)
        dialog.set_resizable(False)

        state = {
            'action': action,
            'dialog': dialog,
            'dirty': False,
            'loading': False,
            'closed': False,
            'request_id': 0,
            'status_token': None,
            'status_timed_out': False,
        }
        self.active_dialog_state = state

        dialog.connect("destroy", self.on_dialog_destroy, state)
        focus_controller = Gtk.EventControllerFocus.new()
        focus_controller.connect("enter", self.on_dialog_focus_in, state)

        if (action.get('status_script') or "").strip():
            self.refresh_action_dialog(state)
        else:
            self.build_action_dialog_content(state, None)

    def on_dialog_destroy(self, _dialog, state):
        """Clear the active dialog reference when the modal closes."""
        state['closed'] = True
        if self.active_dialog_state is state:
            self.active_dialog_state = None

    def on_window_focus_in(self, _widget, _event):
        """Refresh the active dialog on focus return when needed."""
        state = self.active_dialog_state
        if self.should_refresh_dialog(state):
            self.refresh_action_dialog(state)
        return False

    def on_dialog_focus_in(self, _dialog, _event, state):
        """Refresh the focused dialog after a launched action when needed."""
        if self.should_refresh_dialog(state):
            self.refresh_action_dialog(state)
        return False

    def should_refresh_dialog(self, state):
        """Return True when a dialog should refresh its status on focus return."""
        if not state or state.get('closed'):
            return False
        if self.active_dialog_state is not state:
            return False
        if state.get('loading'):
            return False
        return state.get('dirty', False)

    def refresh_action_dialog(self, state):
        """Show the loading state and rerun the dialog status check."""
        if not state or state.get('closed'):
            return

        action = state['action']
        status_script = (action.get('status_script') or "").strip()
        if not status_script:
            self.build_action_dialog_content(state, None)
            return

        state['dirty'] = False
        state['request_id'] += 1
        request_id = state['request_id']
        self.build_action_dialog_loading(state)

        thread = threading.Thread(
            target=self.run_status_check,
            args=(state, request_id, status_script),
            daemon=True,
        )
        thread.start()

    def build_action_dialog_loading(self, state):
        """Render the loading-only modal view."""
        dialog = state['dialog']
        content_area = dialog.get_content_area()
        clear_container(content_area)
        state['loading'] = True

        loading_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        loading_box.set_halign(Gtk.Align.CENTER)
        loading_box.set_valign(Gtk.Align.CENTER)
        set_widget_margins(loading_box, 24, 24, 24, 24)

        spinner = Gtk.Spinner()
        spinner.start()
        loading_box.append(spinner)

        label = Gtk.Label(label="Loading...")
        loading_box.append(label)

        content_area.append(loading_box)
        dialog.set_visible(True)

    def run_status_check(self, state, request_id, status_script):
        """Run the modal status check in the background."""
        status_token = "unknown"
        status_timed_out = False

        try:
            result = subprocess.run(
                build_headless_command(status_script),
                capture_output=True,
                text=True,
                timeout=STATUS_TIMEOUT_SECONDS,
                check=False,
            )

            if result.returncode == 0:
                for line in result.stdout.splitlines():
                    token = line.strip()
                    if token:
                        status_token = token
                        break
        except subprocess.TimeoutExpired:
            status_timed_out = True
        except Exception:
            status_token = "unknown"

        GLib.idle_add(
            self.finish_status_check,
            state,
            request_id,
            status_token,
            status_timed_out,
        )

    def finish_status_check(self, state, request_id, status_token, status_timed_out):
        """Update the dialog once the status check completes."""
        if not state or state.get('closed'):
            return False
        if self.active_dialog_state is not state:
            return False
        if state.get('request_id') != request_id:
            return False

        self.build_action_dialog_content(state, status_token, status_timed_out)
        return False

    def build_action_dialog_content(self, state, status_token, status_timed_out=False):
        """Render the full action dialog after status is known."""
        dialog = state['dialog']
        action = state['action']
        content_area = dialog.get_content_area()
        clear_container(content_area)

        state['loading'] = False
        state['status_token'] = status_token
        state['status_timed_out'] = status_timed_out

        root = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        set_widget_margins(root, 16, 16, 16, 16)

        title_label = Gtk.Label()
        title_label.set_markup(f"<big><b>{escape_markup(action.get('title', 'Action'))}</b></big>")
        title_label.set_xalign(0)
        root.append(title_label)

        description = action.get('description')
        if description:
            desc_label = Gtk.Label(label=description)
            desc_label.set_xalign(0)
            desc_label.set_wrap(True)
            desc_label.get_style_context().add_class('dim-label')
            root.append(desc_label)

        if status_timed_out:
            status_label = Gtk.Label()
            status_label.set_markup(
                "<span foreground='red'><b>Status check timed out. You can still run the action.</b></span>"
            )
            status_label.set_xalign(0)
            status_label.set_wrap(True)
            root.append(status_label)

        actions_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        for option in self.get_action_options(action):
            option_button = Gtk.Button(label=option.get('label', 'Run'))
            option_button.set_hexpand(True)
            option_button.set_halign(Gtk.Align.FILL)

            if self.option_is_highlighted(option, status_token):
                option_button.get_style_context().add_class("suggested-action")

            option_button.connect("clicked", self.on_option_clicked, state, option)
            actions_box.append(option_button)

        root.append(actions_box)

        close_button = Gtk.Button(label="Close")
        close_button.connect("clicked", lambda _button: dialog.destroy())
        root.append(close_button)

        content_area.append(root)
        dialog.set_visible(True)

    def option_is_highlighted(self, option, status_token):
        """Return True when the option ID matches the current status token."""
        if not status_token or status_token == "unknown":
            return False

        option_id = (option.get('id') or "").strip().lower()
        current_status = status_token.strip().lower()
        return bool(option_id) and option_id == current_status

    def on_option_clicked(self, _button, state, option):
        """Launch the selected modal action in a terminal."""
        script = (option.get('script') or "").strip()
        if not script:
            return

        error_message = self.launch_terminal(script)
        if error_message is None:
            if (state['action'].get('status_script') or "").strip():
                state['dirty'] = True
            return

        show_error_dialog(
            state['dialog'],
            "No terminal available",
            "Could not open a terminal automatically.\n\n"
            + error_message
            + "\n\nYou can also run the following command manually:\n\n"
            + script
        )

    def launch_terminal(self, script):
        """Attempt to run a command in a terminal. Returns None on success."""
        try:
            subprocess.Popen(build_terminal_command(script))
            return None
        except FileNotFoundError:
            return "The default terminal launcher (xdg-terminal-exec) was not found."
        except Exception as e:
            return f"Terminal launch failed: {e}"


def main():
    # Check command-line arguments
    if len(sys.argv) != 2:
        print(f"Usage: {APP_ID} CONFIG_FILE")
        print("Example: python3 yafti_gtk.py /path/to/yafti.yml")
        sys.exit(1)

    config_file = sys.argv[1]

    # Initialize GTK before creating the window.
    initialize_gtk()

    loop = GLib.MainLoop()

    # Create and show window
    win = YaftiGTK(config_file)
    win.connect("close-request", lambda *_: loop.quit())
    win.set_visible(True)

    loop.run()


if __name__ == '__main__':
    main()

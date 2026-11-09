"""Package a signed RWKV Chat app with a Finder drop target."""

import argparse
from pathlib import Path
import subprocess
from tempfile import TemporaryDirectory


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('app', type=Path)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()

    app = args.app.resolve()
    output = args.output.parent.resolve() / args.output.name
    if app.name != 'RWKV Chat.app' or not (app / 'Contents/Info.plist').is_file():
        parser.error('app must point to a built RWKV Chat.app')
    if output.suffix != '.dmg' or app in output.parents:
        parser.error('output must be a .dmg path outside the app bundle')
    if output.exists() or output.is_symlink():
        parser.error('output already exists')

    with TemporaryDirectory(prefix='.dmg-staging-', dir=output.parent) as scratch:
        staging = Path(scratch) / 'image'
        staging.mkdir()
        subprocess.run(['/usr/bin/ditto', app, staging / app.name], check=True)
        (staging / 'Applications').symlink_to('/Applications')
        subprocess.run(['/usr/bin/hdiutil', 'create', '-volname', 'RWKV Chat Installer',
                        '-srcfolder', staging, '-format', 'UDZO', output], check=True)

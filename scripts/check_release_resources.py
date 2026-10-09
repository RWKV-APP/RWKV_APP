"""Verify the real resource bytes that enter a release package."""
import argparse
import hashlib
import json
from pathlib import Path
import zipfile


def verify_data(data, environment, expected):
    if len(data) != expected['size'] or hashlib.sha256(data).hexdigest() != expected['sha256']:
        raise ValueError('Release filter asset is missing, empty or differs from the frozen dictionary')
    keys = {line.split('=', 1)[0].strip() for line in environment.splitlines()
            if line.strip() and not line.lstrip().startswith('#') and '=' in line}
    if keys != {'x-api-key'}:
        raise ValueError('Release environment asset must contain only the runtime key')
    return {'filterBytes': len(data), 'filterSha256': expected['sha256'], 'environmentKeys': sorted(keys)}


def verify(root, expected):
    return verify_data((root / 'assets/filter.txt').read_bytes(), (root / '.env').read_text(encoding='utf-8-sig'), expected)


def verify_package(package, expected):
    with zipfile.ZipFile(package) as archive:
        filters = [name for name in archive.namelist() if name.endswith('/flutter_assets/assets/filter.txt')]
        environments = [name for name in archive.namelist() if name.endswith('/flutter_assets/.env')]
        if len(filters) != 1 or len(environments) != 1:
            raise ValueError('Package must contain exactly one complete dictionary and runtime environment')
        return verify_data(archive.read(filters[0]), archive.read(environments[0]).decode('utf-8-sig'), expected)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--asset-root', type=Path, default=Path('.'))
    parser.add_argument('--package', type=Path)
    args = parser.parse_args()
    release = json.loads((Path(__file__).resolve().parents[1] / 'release.json').read_text())
    result = verify_package(args.package, release['resources']['filter']) if args.package else verify(args.asset_root, release['resources']['filter'])
    print(json.dumps(result))

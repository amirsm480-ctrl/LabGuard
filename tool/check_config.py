import argparse
from pathlib import Path
import re
from urllib.parse import urlparse


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('platform', choices=['android', 'web'])
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    source = (root / 'lib/config/app_config.dart').read_text()
    values = dict(re.findall(r'''static\s+const\s+(?:String\s+)?(\w+)\s*=\s*['"]([^'"]*)['"]\s*;''', source))
    app_field = 'webAppId' if args.platform == 'web' else 'androidAppId'
    key_field = 'webApiKey' if args.platform == 'web' else 'apiKey'
    required = [key_field, app_field, 'messagingSenderId', 'projectId', 'databaseUrl', 'labId']
    if args.platform == 'web':
        required.append('authDomain')
    missing = [name for name in required if not values.get(name) or 'REPLACE_' in values[name]]
    if missing:
        raise SystemExit('Fill in lib/config/app_config.dart: ' + ', '.join(missing))
    sender = values['messagingSenderId']
    if not sender.isdigit():
        raise SystemExit('messagingSenderId must contain the Firebase project number in quotes.')
    if not values[app_field].startswith(f'1:{sender}:{args.platform}:'):
        raise SystemExit(f'{app_field} must be the Firebase {args.platform} App ID from the same project.')
    url = urlparse(values['databaseUrl'])
    if url.scheme != 'https' or not url.netloc:
        raise SystemExit('databaseUrl must be the HTTPS URL from Firebase Realtime Database.')
    print(f'Firebase {args.platform} configuration fields are filled in. Credentials were not verified.')


if __name__ == '__main__':
    main()

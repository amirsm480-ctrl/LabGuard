from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import xml.etree.ElementTree as ET


def main():
    root = Path(__file__).resolve().parents[1]
    android = root / 'android'
    if not android.exists():
        flutter = shutil.which('flutter')
        if flutter is None:
            raise SystemExit('Flutter is required to generate Android files. Use the GitHub Android workflow or install Flutter.')
        with tempfile.TemporaryDirectory(prefix='labguard_android_') as directory:
            template = Path(directory) / 'labguard'
            subprocess.run([
                flutter, 'create', '--no-pub', '--empty', '--platforms=android',
                '--org', 'com.amiraziz', '--project-name', 'labguard', str(template),
            ], check=True)
            shutil.copytree(template / 'android', android)
            if not (root / '.metadata').exists():
                shutil.copy2(template / '.metadata', root / '.metadata')

    gradle = android / 'app/build.gradle.kts'
    if gradle.exists():
        source = gradle.read_text()
        pattern = r'\bminSdk\s*=\s*(flutter\.minSdkVersion|\d+)'
        prefix = 'minSdk = '
    else:
        gradle = android / 'app/build.gradle'
        if not gradle.exists():
            raise SystemExit('Android app Gradle file was not found.')
        source = gradle.read_text()
        pattern = r'\bminSdkVersion\s*(?:=\s*)?(flutter\.minSdkVersion|\d+)'
        prefix = 'minSdkVersion '
    package = re.search(r'''\bapplicationId\s*(?:=\s*)?["']([^"']+)["']''', source)
    if package is None or package.group(1) != 'com.amiraziz.labguard':
        raise SystemExit('Use Android applicationId com.amiraziz.labguard, matching the registered Firebase Android app.')
    source, count = re.subn(pattern, lambda match: prefix + str(max(24, int(match.group(1))) if match.group(1).isdigit() else 24), source)
    if count != 1:
        raise SystemExit('Could not locate one Android minSdk setting. Set minSdk to at least 24 manually.')
    gradle.write_text(source)

    namespace = 'http://schemas.android.com/apk/res/android'
    ET.register_namespace('android', namespace)
    manifest_path = android / 'app/src/main/AndroidManifest.xml'
    tree = ET.parse(manifest_path)
    manifest = tree.getroot()
    name_key = '{' + namespace + '}name'
    existing = {item.get(name_key) for item in manifest.findall('uses-permission')}
    for permission in ['android.permission.INTERNET', 'android.permission.ACCESS_NETWORK_STATE']:
        if permission not in existing:
            manifest.insert(0, ET.Element('uses-permission', {name_key: permission}))
    application = manifest.find('application')
    if application is None:
        raise SystemExit('Android application manifest entry was not found.')
    application.set('{' + namespace + '}label', 'LabGuard')
    ET.indent(tree, space='    ')
    tree.write(manifest_path, encoding='utf-8', xml_declaration=True)
    print('Android files are ready. No APK was built by this script.')


if __name__ == '__main__':
    main()

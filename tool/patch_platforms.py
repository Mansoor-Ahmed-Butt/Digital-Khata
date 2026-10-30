#!/usr/bin/env python3
"""Applies the native settings Digital Khata needs after `flutter create .`.
Safe to run more than once."""
import glob, os, re, sys

root = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
os.chdir(root)

def read(p): return open(p, encoding='utf-8').read()
def write(p, s): open(p, 'w', encoding='utf-8').write(s)

# ---- AndroidManifest ------------------------------------------------------
manifest = 'android/app/src/main/AndroidManifest.xml'
if os.path.exists(manifest):
    s = read(manifest)
    perms = [
        'android.permission.INTERNET',
        'android.permission.USE_BIOMETRIC',
        'android.permission.READ_CONTACTS',
    ]
    add = ''.join(f'    <uses-permission android:name="{p}"/>\n' for p in perms if p not in s)
    if add:
        s = s.replace('<application', add + '    <application', 1)
    s = re.sub(r'android:label="[^"]*"', 'android:label="Digital Khata"', s, count=1)
    if 'android:allowBackup' not in s:
        s = s.replace('<application', '<application\n        android:allowBackup="false"', 1)
    intents = '''        <intent><action android:name="android.intent.action.VIEW"/><data android:scheme="https"/></intent>
        <intent><action android:name="android.intent.action.SENDTO"/><data android:scheme="sms"/></intent>
        <package android:name="com.whatsapp"/>
        <package android:name="com.whatsapp.w4b"/>
'''
    if 'com.whatsapp' not in s:
        if '<queries>' in s:
            s = s.replace('<queries>', '<queries>\n' + intents, 1)
        else:
            s = s.replace('</manifest>', '    <queries>\n' + intents + '    </queries>\n</manifest>', 1)
    write(manifest, s)
    print('patched', manifest)

# ---- MainActivity (local_auth needs FlutterFragmentActivity) ---------------
for path in glob.glob('android/app/src/main/kotlin/**/MainActivity.kt', recursive=True):
    s = read(path)
    pkg = re.search(r'^package\s+([\w.]+)', s, re.M).group(1)
    write(path, f'''package {pkg}

import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity()
''')
    print('patched', path)

# ---- minSdk 26 (Android 8) ------------------------------------------------
for gradle in ('android/app/build.gradle.kts', 'android/app/build.gradle'):
    if os.path.exists(gradle):
        s = read(gradle)
        s = re.sub(r'minSdk\s*=\s*flutter\.minSdkVersion', 'minSdk = 26', s)
        s = re.sub(r'minSdkVersion\s+flutter\.minSdkVersion', 'minSdkVersion 26', s)
        write(gradle, s)
        print('patched', gradle)

# ---- AppCompat launch theme (biometric prompt) ----------------------------
for styles in glob.glob('android/app/src/main/res/values*/styles.xml'):
    s = read(styles)
    s2 = re.sub(r'@android:style/Theme\.(Light|Black)\.NoTitleBar', 'Theme.AppCompat.DayNight.NoActionBar', s)
    if s2 != s:
        write(styles, s2)
        print('patched', styles)

# ---- iOS usage strings ----------------------------------------------------
plist = 'ios/Runner/Info.plist'
if os.path.exists(plist):
    s = read(plist)
    keys = {
        'NSContactsUsageDescription': 'Import customers from your contacts.',
        'NSFaceIDUsageDescription': 'Unlock Digital Khata with Face ID.',
        'NSCameraUsageDescription': 'Attach a photo of a bill to an entry.',
        'NSPhotoLibraryUsageDescription': 'Attach a bill photo from your gallery.',
        'LSApplicationQueriesSchemes': None,
    }
    add = ''
    for k, v in keys.items():
        if k in s:
            continue
        if v is None:
            add += '\t<key>LSApplicationQueriesSchemes</key>\n\t<array>\n\t\t<string>whatsapp</string>\n\t\t<string>sms</string>\n\t</array>\n'
        else:
            add += f'\t<key>{k}</key>\n\t<string>{v}</string>\n'
    if add:
        s = s.replace('</dict>\n</plist>', add + '</dict>\n</plist>')
        write(plist, s)
    print('patched', plist)

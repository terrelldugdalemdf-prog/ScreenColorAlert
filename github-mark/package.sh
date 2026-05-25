#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$PROJECT_DIR/.build"
APP_NAME="ScreenColorAlert"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
DMG_FILE="$BUILD_DIR/$APP_NAME.dmg"
DMG_TMP="$BUILD_DIR/dmg_temp"
VOLUME_NAME="屏幕颜色监测"
HAS_ICON=false
[ -f "$PROJECT_DIR/AppIcon.icns" ] && HAS_ICON=true

# 清理残余挂载
for v in /Volumes/"$VOLUME_NAME"*; do
    hdiutil detach "$v" -force 2>/dev/null || true
done
sleep 1

echo "=== 1. 编译 Release 版本 ==="
swift build -c release --disable-sandbox

echo "=== 2. 打包 .app ==="
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BUILD_DIR/release/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/"

if $HAS_ICON; then
    cp "$PROJECT_DIR/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/"
fi

# 生成 Info.plist
if $HAS_ICON; then
    ICON_PLIST_KEY="<key>CFBundleIconFile</key>
    <string>AppIcon</string>"
else
    ICON_PLIST_KEY=""
fi

cat > "$APP_BUNDLE/Contents/Info.plist" << PLIST_END
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>ScreenColorAlert</string>
    <key>CFBundleDisplayName</key>
    <string>屏幕颜色监测</string>
    <key>CFBundleIdentifier</key>
    <string>com.screen-color-alert.app</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>ScreenColorAlert</string>
$ICON_PLIST_KEY
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSScreenCaptureUsageDescription</key>
    <string>屏幕颜色监测需要截取屏幕内容来识别指定区域的颜色。</string>
</dict>
</plist>
PLIST_END

# 通过 NSWorkspace 设置图标（绕过 CFBundleIconFile 在 SwiftPM 构建中的不可靠问题）
if $HAS_ICON; then
    swift -e '
import AppKit
let iconPath = "'"$APP_BUNDLE"'/Contents/Resources/AppIcon.icns"
let appPath = "'"$APP_BUNDLE"'"
guard let icon = NSImage(contentsOfFile: iconPath) else {
    fatalError("无法加载图标文件")
}
let ok = NSWorkspace.shared.setIcon(icon, forFile: appPath, options: [])
if !ok { fatalError("图标写入失败") }
print("图标已嵌入 app bundle")
' || { echo "图标设置失败"; exit 1; }
fi

touch "$APP_BUNDLE"

echo "=== 3. 创建 DMG ==="
rm -rf "$DMG_TMP" "$DMG_FILE"

mkdir -p "$DMG_TMP"
cp -R "$APP_BUNDLE" "$DMG_TMP/"
ln -s /Applications "$DMG_TMP/Applications"

hdiutil create \
  -volname "$VOLUME_NAME" \
  -srcfolder "$DMG_TMP" \
  -ov \
  -format UDRW \
  -size 100m \
  "$BUILD_DIR/tmp.dmg"

hdiutil attach -readwrite -noverify -noautoopen "$BUILD_DIR/tmp.dmg" > /dev/null
MOUNT_POINT="/Volumes/$VOLUME_NAME"
echo "已挂载: $MOUNT_POINT"

# AppleScript 布局
osascript << 'APPLESCRIPT'
tell application "Finder"
    set volumeName to "屏幕颜色监测"
    tell disk volumeName
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {400, 200, 900, 500}
        set theViewOptions to the icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to 72
        set text size of theViewOptions to 12
        set position of item "ScreenColorAlert.app" to {120, 120}
        set position of item "Applications" to {380, 120}
        close
        open
        update without registering applications
    end tell
end tell
APPLESCRIPT

sleep 2
hdiutil detach "$MOUNT_POINT" -force
sleep 2

echo "=== 4. 压缩 DMG ==="
hdiutil convert "$BUILD_DIR/tmp.dmg" \
  -format UDZO \
  -imagekey zlib-level=9 \
  -o "$DMG_FILE" || {
    sleep 3
    hdiutil convert "$BUILD_DIR/tmp.dmg" \
      -format UDZO \
      -imagekey zlib-level=9 \
      -o "$DMG_FILE"
}

rm -f "$BUILD_DIR/tmp.dmg"
rm -rf "$DMG_TMP"

echo ""
echo "========================================="
echo "  打包完成！"
echo "  DMG: $DMG_FILE"
echo "  大小: $(du -h "$DMG_FILE" | awk '{print $1}')"
echo "========================================="

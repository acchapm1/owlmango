if test -d $HOME/.local/share/android-sdk/
  set -x ANDROID_HOME $HOME/.local/share/android-sdk/
  set -x ANDROID_SDK_ROOT $HOME/.local/share/android-sdk/

  set -x PATH "$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools/:$ANDROID_HOME/emulator/:$PATH"
end

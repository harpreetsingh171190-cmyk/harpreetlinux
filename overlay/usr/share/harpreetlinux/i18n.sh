# Shared window texts for HarpreetLinux tools (sh and bash).
# Use:  . /usr/share/harpreetlinux/i18n.sh   then read the HL_* variables.
case "${LC_ALL:-${LC_MESSAGES:-${LANG:-}}}" in
  pa*)
    HL_LANG=pa
    HL_SETUP_TITLE="ਹਰਪ੍ਰੀਤ ਲੀਨਕਸ ਸੈੱਟਅੱਪ"
    HL_SETUP_TEXT="ਇੰਸਟਾਲ ਕਰਨ ਲਈ ਟੂਲ ਗਰੁੱਪ ਚੁਣੋ। ਇੰਟਰਨੈੱਟ ਚਾਹੀਦਾ ਹੈ।"
    HL_COL_INSTALL="ਇੰਸਟਾਲ"
    HL_COL_GROUP="ਗਰੁੱਪ"
    HL_COL_DESC="ਵੇਰਵਾ"
    HL_WELCOME_TITLE="ਹਰਪ੍ਰੀਤ ਲੀਨਕਸ ਵਿੱਚ ਜੀ ਆਇਆਂ ਨੂੰ"
    HL_WELCOME_TEXT="ਹਰਪ੍ਰੀਤ ਲੀਨਕਸ ਵਰਤਣ ਲਈ ਧੰਨਵਾਦ।

ਸੈੱਟਅੱਪ ਮੀਨੂ ਤੋਂ ਟੂਲ ਗਰੁੱਪ (ਗੇਮਿੰਗ, ਮਲਟੀਮੀਡੀਆ, ਡਿਜ਼ਾਈਨ, ਡਿਵੈਲਪਮੈਂਟ, ਸੁਰੱਖਿਆ ਆਦਿ) ਚੁਣੋ। ਇੰਟਰਨੈੱਟ ਕੁਨੈਕਸ਼ਨ ਚਾਹੀਦਾ ਹੈ।"
    HL_WELCOME_OK="ਟੂਲ ਗਰੁੱਪ ਇੰਸਟਾਲ ਕਰੋ"
    HL_WELCOME_CLOSE="ਬੰਦ ਕਰੋ"
    HL_WELCOME_STORE="ਸੌਫਟਵੇਅਰ ਸਟੋਰ ਖੋਲ੍ਹੋ"
    HL_LANG_TITLE="ਭਾਸ਼ਾ ਬਦਲੋ"
    HL_LANG_TEXT="ਸਿਸਟਮ ਦੀ ਭਾਸ਼ਾ ਚੁਣੋ:"
    HL_LANG_COL="ਭਾਸ਼ਾ"
    HL_LANG_DONE="ਭਾਸ਼ਾ ਬਦਲ ਦਿੱਤੀ ਗਈ ਹੈ। ਨਵੀਂ ਭਾਸ਼ਾ ਲਈ ਲੌਗ ਆਊਟ ਕਰਕੇ ਦੁਬਾਰਾ ਲੌਗ ਇਨ ਕਰੋ।"
    HL_LANG_FAIL="ਭਾਸ਼ਾ ਨਹੀਂ ਬਦਲੀ ਜਾ ਸਕੀ।"
    ;;
  *)
    HL_LANG=en
    HL_SETUP_TITLE="HarpreetLinux Setup"
    HL_SETUP_TEXT="Choose tool groups to install. Internet is needed."
    HL_COL_INSTALL="Install"
    HL_COL_GROUP="Group"
    HL_COL_DESC="Description"
    HL_WELCOME_TITLE="Welcome to HarpreetLinux"
    HL_WELCOME_TEXT="Thank you for using HarpreetLinux.

Choose tool groups (gaming, multimedia, design, development, security and more) from the setup menu. An internet connection is needed."
    HL_WELCOME_OK="Install tool groups"
    HL_WELCOME_CLOSE="Close"
    HL_WELCOME_STORE="Open software store"
    HL_LANG_TITLE="Change language"
    HL_LANG_TEXT="Choose the system language:"
    HL_LANG_COL="Language"
    HL_LANG_DONE="Language changed. Log out and log in again to use it."
    HL_LANG_FAIL="Could not change the language."
    ;;
esac

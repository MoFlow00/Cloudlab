# APP_NAME=PDFCraft
# خطوات تثبيت PDFCraft - اكتب أوامر التثبيت هنا بالترتيب.
# تقدر تضيف أو تحذف أو تعدل الأوامر من غير ما تلمس menu.sh.

set -e

mkdir -p "$HOME/Downloads"
cd "$HOME/Downloads"

wget -O pdfcraft-0.13.0-linux-x86_64.deb   https://github.com/storytold/pdfcraft/releases/download/v0.13.0/pdfcraft-0.13.0-linux-x86_64.deb

sudo apt update
sudo apt install -y ./pdfcraft-0.13.0-linux-x86_64.deb
sudo apt install -y libxkbcommon-x11-0 libxcb-xkb1

echo "PDFCraft installed. Try opening it from Applications."

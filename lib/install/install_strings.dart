/// Words of the "Cài ứng dụng" guide in every language a ViMai customer's
/// phone may use. `**bold**` marks button names; `{app}` is the app name.
///
/// Button names follow what the phone itself shows in that language
/// (Safari's 共有 / ホーム画面に追加, Chrome's アプリをインストール...).
class InstallStrings {
  const InstallStrings({
    required this.eyebrow,
    required this.title,
    required this.intro,
    required this.chipOneTap,
    required this.chipFullScreen,
    required this.chipProgress,
    required this.installNow,
    required this.oneTapNote,
    required this.installed,
    required this.note,
    required this.close,
    required this.copyLink,
    required this.copied,
    required this.pill,
    required this.iosSteps,
    required this.androidSteps,
    required this.share,
    required this.swipeUp,
    required this.favourites,
    required this.findOnPage,
    required this.addToHome,
    required this.menu,
    required this.installApp,
  });

  final String eyebrow;
  final String title;
  final String intro;
  final String chipOneTap;
  final String chipFullScreen;
  final String chipProgress;
  final String installNow;
  final String oneTapNote;
  final String installed;
  final String note;
  final String close;
  final String copyLink;
  final String copied;

  /// The small button at the top of the app.
  final String pill;

  /// Three (title, body) pairs each.
  final List<(String, String)> iosSteps;
  final List<(String, String)> androidSteps;

  // Words drawn in the illustrations.
  final String share;
  final String swipeUp;
  final String favourites;
  final String findOnPage;
  final String addToHome;
  final String menu;
  final String installApp;

  static const supported = ['vi', 'en', 'ja', 'id', 'zh', 'ko', 'th'];

  /// The language the customer reads the app in, unless the phone speaks a
  /// language the app itself does not offer (an Indonesian phone on an app in
  /// vi/en): then the phone's. English when neither is known.
  static String pick({String? device, String? app, List<String> appLanguages = const ['vi', 'en']}) {
    String? code(String? tag) {
      if (tag == null || tag.isEmpty) return null;
      final c = tag.toLowerCase().split(RegExp('[-_]')).first;
      return supported.contains(c) ? c : null;
    }

    final phone = code(device);
    final chosen = code(app);
    if (phone != null && !appLanguages.contains(phone)) return phone;
    return chosen ?? phone ?? 'en';
  }

  static InstallStrings of(String lang) => switch (lang) {
        'vi' => vi,
        'ja' => ja,
        'id' => id,
        'zh' => zh,
        'ko' => ko,
        'th' => th,
        _ => en,
      };

  static String fill(String s, String app) => s.replaceAll('{app}', app);

  static const vi = InstallStrings(
    eyebrow: 'LUÔN SẴN TRONG MÁY',
    title: 'Cài {app} lên điện thoại',
    intro: 'Mở {app} bằng một chạm từ màn hình chính, toàn màn hình như app thật. '
        'Không cần App Store, gần như không tốn dung lượng, tiến độ học giữ nguyên.',
    chipOneTap: 'Mở 1 chạm',
    chipFullScreen: 'Toàn màn hình',
    chipProgress: 'Giữ tiến độ',
    installNow: 'Cài {app} ngay',
    oneTapNote: 'Trình duyệt này cài được bằng một chạm. Hoặc làm theo các bước dưới.',
    installed: 'Đã cài {app}. Mở từ màn hình chính nhé!',
    note: 'Hình minh hoạ thao tác; vị trí và tên nút có thể khác theo phiên bản trình duyệt.',
    close: 'Đóng',
    copyLink: 'Sao chép link',
    copied: 'Đã chép link',
    pill: 'Cài ứng dụng',
    iosSteps: [
      (
        'Mở bằng Safari',
        'Cài từ **Safari**. Nếu đang xem trong Facebook, Zalo hay Messenger: bấm ⋯ rồi chọn '
            '**Mở bằng trình duyệt**, hoặc sao chép link dán vào Safari.',
      ),
      (
        'Bấm Chia sẻ',
        'Bấm nút **Chia sẻ** ở thanh dưới của Safari, **vuốt bảng lên** (hoặc bấm **Xem thêm**) '
            'rồi chọn **Thêm vào Màn hình chính**.',
      ),
      (
        'Thêm và mở ứng dụng',
        'Bật **Mở dưới dạng ứng dụng web** nếu có, rồi bấm **Thêm**. Về màn hình chính và mở '
            'biểu tượng **{app}**.',
      ),
    ],
    androidSteps: [
      (
        'Mở bằng Chrome',
        'Cài từ **Chrome** (hoặc Samsung Internet). Trong Facebook, Zalo: bấm ⋮ rồi chọn '
            '**Mở bằng trình duyệt**.',
      ),
      ('Mở menu ⋮', 'Bấm ⋮ ở góc trên bên phải, chọn **Cài đặt ứng dụng** hoặc **Thêm vào màn hình chính**.'),
      ('Cài và mở ứng dụng', 'Bấm **Cài đặt**. Biểu tượng **{app}** có trên màn hình chính và trong danh sách ứng dụng.'),
    ],
    share: 'Chia sẻ',
    swipeUp: 'Vuốt lên',
    favourites: 'Thêm vào Mục ưa thích',
    findOnPage: 'Tìm trên trang',
    addToHome: 'Thêm vào Màn hình chính',
    menu: 'Menu',
    installApp: 'Cài đặt ứng dụng',
  );

  static const en = InstallStrings(
    eyebrow: 'ALWAYS ON YOUR PHONE',
    title: 'Install {app} on your phone',
    intro: 'Open {app} with one tap from your home screen, full screen like a real app. '
        'No app store, almost no storage, your progress stays.',
    chipOneTap: 'One tap',
    chipFullScreen: 'Full screen',
    chipProgress: 'Keeps progress',
    installNow: 'Install {app} now',
    oneTapNote: 'This browser installs in one tap. Or follow the steps below.',
    installed: '{app} is installed. Open it from your home screen!',
    note: 'Illustrations only; button names and places can differ between browser versions.',
    close: 'Close',
    copyLink: 'Copy link',
    copied: 'Link copied',
    pill: 'Install app',
    iosSteps: [
      (
        'Open in Safari',
        'Install from **Safari**. If you are inside Facebook, WhatsApp or Messenger, tap ⋯ and '
            'choose **Open in Browser**, or copy the link into Safari.',
      ),
      ('Tap Share', 'Tap **Share** in the Safari toolbar, **swipe the sheet up** and choose **Add to Home Screen**.'),
      ('Add and open', 'Turn on **Open as Web App** if shown, then tap **Add**. Open **{app}** from your home screen.'),
    ],
    androidSteps: [
      (
        'Open in Chrome',
        'Install from **Chrome** (or Samsung Internet). Inside Facebook, tap ⋮ and choose **Open in browser**.',
      ),
      ('Open the ⋮ menu', 'Tap ⋮ at the top right and choose **Install app** or **Add to Home screen**.'),
      ('Install and open', 'Tap **Install**. The **{app}** icon appears on your home screen and in your apps.'),
    ],
    share: 'Share',
    swipeUp: 'Swipe up',
    favourites: 'Add to Favourites',
    findOnPage: 'Find on Page',
    addToHome: 'Add to Home Screen',
    menu: 'Menu',
    installApp: 'Install app',
  );

  static const ja = InstallStrings(
    eyebrow: 'いつでもスマホに',
    title: '{app}をスマホにインストール',
    intro: 'ホーム画面からワンタップで、アプリのように全画面で開けます。'
        'App Store不要、容量もほとんど使わず、学習の記録もそのままです。',
    chipOneTap: 'ワンタップ',
    chipFullScreen: '全画面',
    chipProgress: '記録はそのまま',
    installNow: '{app}をインストール',
    oneTapNote: 'このブラウザはワンタップでインストールできます。下の手順でも大丈夫です。',
    installed: '{app}をインストールしました。ホーム画面から開いてください。',
    note: '操作のイメージです。ボタンの位置や名前はブラウザのバージョンによって異なる場合があります。',
    close: '閉じる',
    copyLink: 'リンクをコピー',
    copied: 'コピーしました',
    pill: 'アプリを追加',
    iosSteps: [
      (
        'Safariで開く',
        '**Safari**からインストールします。Facebook・LINE・Messengerの中で見ている場合は、⋯から'
            '**ブラウザで開く**を選ぶか、リンクをコピーしてSafariに貼り付けてください。',
      ),
      ('共有をタップ', 'Safariのツールバーの**共有**をタップし、**シートを上にスワイプ**して**ホーム画面に追加**を選びます。'),
      (
        '追加して開く',
        '**Webアプリとして開く**が表示されたらオンにして、**追加**をタップ。ホーム画面の**{app}**から開きます。',
      ),
    ],
    androidSteps: [
      (
        'Chromeで開く',
        '**Chrome**（またはSamsung Internet）からインストールします。FacebookやLINEの中では、⋮から**ブラウザで開く**を選んでください。',
      ),
      ('⋮メニューを開く', '右上の⋮をタップし、**アプリをインストール**または**ホーム画面に追加**を選びます。'),
      ('インストールして開く', '**インストール**をタップ。**{app}**のアイコンがホーム画面とアプリ一覧に追加されます。'),
    ],
    share: '共有',
    swipeUp: '上にスワイプ',
    favourites: 'お気に入りに追加',
    findOnPage: 'ページを検索',
    addToHome: 'ホーム画面に追加',
    menu: 'メニュー',
    installApp: 'アプリをインストール',
  );

  static const id = InstallStrings(
    eyebrow: 'SELALU ADA DI PONSEL',
    title: 'Pasang {app} di ponsel',
    intro: 'Buka {app} dengan sekali ketuk dari layar utama, layar penuh seperti aplikasi. '
        'Tanpa App Store, hampir tidak memakai memori, progres belajar tetap tersimpan.',
    chipOneTap: 'Sekali ketuk',
    chipFullScreen: 'Layar penuh',
    chipProgress: 'Progres tersimpan',
    installNow: 'Pasang {app} sekarang',
    oneTapNote: 'Browser ini bisa memasang dengan sekali ketuk. Atau ikuti langkah di bawah.',
    installed: '{app} sudah terpasang. Buka dari layar utama!',
    note: 'Hanya ilustrasi; nama dan letak tombol bisa berbeda menurut versi browser.',
    close: 'Tutup',
    copyLink: 'Salin tautan',
    copied: 'Tautan disalin',
    pill: 'Pasang aplikasi',
    iosSteps: [
      (
        'Buka di Safari',
        'Pasang dari **Safari**. Jika sedang di Facebook, WhatsApp atau Messenger, ketuk ⋯ lalu pilih '
            '**Buka di browser**, atau salin tautan ke Safari.',
      ),
      ('Ketuk Bagikan', 'Ketuk **Bagikan** di bilah Safari, **geser lembar ke atas**, lalu pilih **Tambah ke Layar Utama**.'),
      ('Tambah dan buka', 'Aktifkan **Buka sebagai App Web** jika ada, lalu ketuk **Tambah**. Buka **{app}** dari layar utama.'),
    ],
    androidSteps: [
      (
        'Buka di Chrome',
        'Pasang dari **Chrome** (atau Samsung Internet). Di dalam Facebook, ketuk ⋮ lalu pilih **Buka di browser**.',
      ),
      ('Buka menu ⋮', 'Ketuk ⋮ di kanan atas, pilih **Instal aplikasi** atau **Tambahkan ke layar utama**.'),
      ('Instal dan buka', 'Ketuk **Instal**. Ikon **{app}** muncul di layar utama dan daftar aplikasi.'),
    ],
    share: 'Bagikan',
    swipeUp: 'Geser ke atas',
    favourites: 'Tambah ke Favorit',
    findOnPage: 'Cari di Halaman',
    addToHome: 'Tambah ke Layar Utama',
    menu: 'Menu',
    installApp: 'Instal aplikasi',
  );

  static const zh = InstallStrings(
    eyebrow: '随时在手机上',
    title: '把{app}安装到手机',
    intro: '从主屏幕一键打开{app}，像 App 一样全屏使用。无需 App Store，几乎不占空间，学习进度也会保留。',
    chipOneTap: '一键打开',
    chipFullScreen: '全屏',
    chipProgress: '保留进度',
    installNow: '立即安装{app}',
    oneTapNote: '此浏览器可一键安装，也可按下面的步骤操作。',
    installed: '{app}已安装，请从主屏幕打开！',
    note: '仅为示意图；按钮的位置和名称可能因浏览器版本而不同。',
    close: '关闭',
    copyLink: '复制链接',
    copied: '已复制',
    pill: '安装应用',
    iosSteps: [
      (
        '用 Safari 打开',
        '请在 **Safari** 中安装。如果正在微信、Facebook 或 Messenger 中浏览，请点 ⋯ 选择**在浏览器中打开**，或复制链接粘贴到 Safari。',
      ),
      ('点击共享', '点击 Safari 工具栏中的**共享**，**向上滑动面板**，然后选择**添加到主屏幕**。'),
      ('添加并打开', '如有**作为网页 App 打开**的选项请打开，然后点**添加**。回到主屏幕，打开 **{app}**。'),
    ],
    androidSteps: [
      ('用 Chrome 打开', '请在 **Chrome**（或三星浏览器）中安装。在 Facebook 等应用内，请点 ⋮ 选择**在浏览器中打开**。'),
      ('打开 ⋮ 菜单', '点击右上角的 ⋮，选择**安装应用**或**添加到主屏幕**。'),
      ('安装并打开', '点击**安装**。**{app}** 图标会出现在主屏幕和应用列表中。'),
    ],
    share: '共享',
    swipeUp: '向上滑动',
    favourites: '添加到个人收藏',
    findOnPage: '在页面上查找',
    addToHome: '添加到主屏幕',
    menu: '菜单',
    installApp: '安装应用',
  );

  static const ko = InstallStrings(
    eyebrow: '언제나 내 폰에',
    title: '{app} 휴대폰에 설치',
    intro: '홈 화면에서 한 번 탭으로 {app}을(를) 앱처럼 전체 화면으로 엽니다. '
        'App Store 없이, 저장 공간도 거의 쓰지 않고, 학습 기록도 그대로입니다.',
    chipOneTap: '한 번 탭',
    chipFullScreen: '전체 화면',
    chipProgress: '기록 유지',
    installNow: '{app} 지금 설치',
    oneTapNote: '이 브라우저는 한 번 탭으로 설치할 수 있습니다. 아래 단계를 따라도 됩니다.',
    installed: '{app} 설치 완료! 홈 화면에서 여세요.',
    note: '설명용 그림입니다. 버튼 위치와 이름은 브라우저 버전에 따라 다를 수 있습니다.',
    close: '닫기',
    copyLink: '링크 복사',
    copied: '복사됨',
    pill: '앱 설치',
    iosSteps: [
      (
        'Safari로 열기',
        '**Safari**에서 설치하세요. 카카오톡, Facebook, Messenger 안에서 보고 있다면 ⋯를 눌러 '
            '**브라우저로 열기**를 선택하거나 링크를 복사해 Safari에 붙여 넣으세요.',
      ),
      ('공유 탭하기', 'Safari 도구 막대의 **공유**를 탭하고 **시트를 위로 쓸어 올린** 다음 **홈 화면에 추가**를 선택하세요.'),
      ('추가하고 열기', '**웹 앱으로 열기**가 보이면 켜고 **추가**를 탭하세요. 홈 화면에서 **{app}**을(를) 여세요.'),
    ],
    androidSteps: [
      ('Chrome으로 열기', '**Chrome**(또는 삼성 인터넷)에서 설치하세요. 카카오톡이나 Facebook 안에서는 ⋮를 눌러 **브라우저로 열기**를 선택하세요.'),
      ('⋮ 메뉴 열기', '오른쪽 위의 ⋮를 탭하고 **앱 설치** 또는 **홈 화면에 추가**를 선택하세요.'),
      ('설치하고 열기', '**설치**를 탭하세요. **{app}** 아이콘이 홈 화면과 앱 목록에 나타납니다.'),
    ],
    share: '공유',
    swipeUp: '위로 쓸어 올리기',
    favourites: '즐겨찾기에 추가',
    findOnPage: '페이지에서 찾기',
    addToHome: '홈 화면에 추가',
    menu: '메뉴',
    installApp: '앱 설치',
  );

  static const th = InstallStrings(
    eyebrow: 'อยู่ในมือถือเสมอ',
    title: 'ติดตั้ง {app} บนมือถือ',
    intro: 'เปิด {app} ได้ในแตะเดียวจากหน้าจอโฮม เต็มจอเหมือนแอปจริง '
        'ไม่ต้องใช้ App Store แทบไม่กินพื้นที่ และความคืบหน้าการเรียนยังอยู่ครบ',
    chipOneTap: 'แตะเดียว',
    chipFullScreen: 'เต็มจอ',
    chipProgress: 'เก็บความคืบหน้า',
    installNow: 'ติดตั้ง {app} ตอนนี้',
    oneTapNote: 'เบราว์เซอร์นี้ติดตั้งได้ในแตะเดียว หรือทำตามขั้นตอนด้านล่าง',
    installed: 'ติดตั้ง {app} แล้ว เปิดจากหน้าจอหลักได้เลย!',
    note: 'ภาพประกอบเท่านั้น ตำแหน่งและชื่อปุ่มอาจต่างกันตามเวอร์ชันเบราว์เซอร์',
    close: 'ปิด',
    copyLink: 'คัดลอกลิงก์',
    copied: 'คัดลอกแล้ว',
    pill: 'ติดตั้งแอป',
    iosSteps: [
      (
        'เปิดด้วย Safari',
        'ติดตั้งจาก **Safari** ถ้ากำลังดูใน Facebook, LINE หรือ Messenger ให้แตะ ⋯ แล้วเลือก '
            '**เปิดในเบราว์เซอร์** หรือคัดลอกลิงก์ไปวางใน Safari',
      ),
      ('แตะแชร์', 'แตะ **แชร์** ที่แถบเครื่องมือ Safari **ปัดแผ่นขึ้น** แล้วเลือก **เพิ่มไปยังหน้าจอโฮม**'),
      ('เพิ่มและเปิด', 'ถ้ามี **เปิดเป็นเว็บแอป** ให้เปิดไว้ แล้วแตะ **เพิ่ม** จากนั้นเปิด **{app}** จากหน้าจอโฮม'),
    ],
    androidSteps: [
      ('เปิดด้วย Chrome', 'ติดตั้งจาก **Chrome** (หรือ Samsung Internet) ถ้าอยู่ใน Facebook หรือ LINE ให้แตะ ⋮ แล้วเลือก **เปิดในเบราว์เซอร์**'),
      ('เปิดเมนู ⋮', 'แตะ ⋮ ที่มุมขวาบน เลือก **ติดตั้งแอป** หรือ **เพิ่มลงในหน้าจอหลัก**'),
      ('ติดตั้งและเปิด', 'แตะ **ติดตั้ง** ไอคอน **{app}** จะอยู่บนหน้าจอหลักและในรายการแอป'),
    ],
    share: 'แชร์',
    swipeUp: 'ปัดขึ้น',
    favourites: 'เพิ่มในรายการโปรด',
    findOnPage: 'ค้นหาในหน้า',
    addToHome: 'เพิ่มไปยังหน้าจอโฮม',
    menu: 'เมนู',
    installApp: 'ติดตั้งแอป',
  );
}

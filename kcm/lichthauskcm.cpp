// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Lichthaus's settings in KDE System Settings: one KCM per Configure page of
// the widget. The page is the widget's own file (package/contents/ui), found
// in the installed widget, so a change to it shows in the widget's Configure
// dialog, in the `lichthaus config` window and here alike.
//
// The pages `import org.kde.plasma.plasmoid`, which only works inside
// plasmashell. The standalone window gives them a stand-in
// (contents/standalone/imports, first on its import path), and so does this
// KCM; but the import path belongs to a QML engine, and System Settings runs
// all its QML KCMs and its own window on one shared engine. A stand-in put
// there would answer every `import org.kde.plasma.plasmoid` in System
// Settings. So this is a QWidget KCM whose QQuickWidget has a QML engine of
// its own, with the stand-in on its import path: the page's imports resolve
// there, nothing else sees them. The page is hosted by
// contents/standalone/kcm.qml from the same package; like the window, the KCM
// acts as widget 1.
//
// Arguments: "add" opens the Bulbs page's Add dialog (`systemsettings
// kcm_lichthaus_bulbs --args add`, the popup's "Connect new bulb…"), also when
// the page is open already.
#include "lichthauskcm.h"

#include <QDir>
#include <QFileInfo>
#include <QLabel>
#include <QLocale>
#include <QtMath>
#include <QQmlEngine>
#include <QQmlError>
#include <QQuickItem>
#include <QQuickWidget>
#include <QStandardPaths>
#include <QVBoxLayout>

using namespace Qt::Literals::StringLiterals;

namespace
{
const auto packageId = u"lichthaus.tray"_s;
const auto hostFile = u"contents/standalone/kcm.qml"_s;
const auto importsDir = u"contents/standalone/imports"_s;

bool german()
{
    return QLocale().name().startsWith(u"de"_s);
}

QString expandHome(const QString &path)
{
    if (path == u"~"_s || path.startsWith(u"~/"_s)) {
        return QDir::homePath() + path.mid(1);
    }
    return path;
}

// Where the widget's package may be, in the order `lichthaus config` tries
// them: $LICHTHAUS_PLASMOID, the widget installed per user or system-wide
// (the XDG data directories), and ~/.local/share/lichthaus/plasmoid (unpacked
// by Lichthaus's install.sh where there is no kpackagetool6).
QStringList packageDirs()
{
    QStringList dirs;
    const QString env = qEnvironmentVariable("LICHTHAUS_PLASMOID");
    if (!env.isEmpty()) {
        dirs << QDir::cleanPath(expandHome(env));
    }
    dirs << QStandardPaths::locateAll(QStandardPaths::GenericDataLocation, u"plasma/plasmoids/"_s + packageId, QStandardPaths::LocateDirectory);
    dirs << QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) + u"/lichthaus/plasmoid"_s;
    return dirs;
}

// The first package that has the KCM host; an older widget without it is
// passed over.
QString findPackage()
{
    for (const QString &dir : packageDirs()) {
        if (QFileInfo(dir + u'/' + hostFile).isFile()) {
            return dir;
        }
    }
    return {};
}

// The page's own size as the widget's size hint, as KCMUtils' host of QML
// KCMs gives it (kcmshell6 opens its window at that size); QQuickWidget's own
// is the root item's size when it was loaded, before it follows the view.
class PageView : public QQuickWidget
{
public:
    using QQuickWidget::QQuickWidget;

    QSize sizeHint() const override
    {
        if (const QQuickItem *root = rootObject()) {
            return QSize(qCeil(root->implicitWidth()), qCeil(root->implicitHeight()));
        }
        return QQuickWidget::sizeHint();
    }
};

bool wantsAddBulb(const QVariantList &args)
{
    for (const QVariant &arg : args) {
        if (arg.toString() == u"add"_s) {
            return true;
        }
    }
    return false;
}
} // namespace

LichthausKcm::LichthausKcm(QObject *parent, const KPluginMetaData &data, const QVariantList &args)
    : KCModule(parent, data)
{
    // The pages change the daemon directly: nothing to apply or reset.
    setButtons(NoAdditionalButton);

    auto layout = new QVBoxLayout(widget());
    layout->setContentsMargins(0, 0, 0, 0);

    const QString page = data.value(u"X-Lichthaus-Page"_s);
    const QString package = findPackage();
    if (package.isEmpty()) {
        showMessage(german() ? u"Die Seiten von Lichthaus wurden nicht gefunden: Das Lichthaus-Widget (Lichthaus-plasma) ist nicht installiert oder zu alt (ohne contents/standalone/kcm.qml)."_s
                             : u"Lichthaus's pages were not found: the Lichthaus widget (Lichthaus-plasma) is not installed or too old (no contents/standalone/kcm.qml)."_s);
        return;
    }

    m_engine = std::make_unique<QQmlEngine>();
    m_engine->addImportPath(package + u'/' + importsDir);

    m_view = new PageView(m_engine.get(), widget());
    // As KCMUtils hosts QML KCMs (kcmoduleqml.cpp): System Settings' own
    // background shows through.
    m_view->setResizeMode(QQuickWidget::SizeRootObjectToView);
    m_view->setAttribute(Qt::WA_AlwaysStackOnTop, true);
    m_view->setAttribute(Qt::WA_NoMousePropagation, true);
    m_view->setClearColor(Qt::transparent);
    m_view->setInitialProperties({
        {u"pageSource"_s, page},
        {u"pageTitle"_s, data.name()},
        {u"addBulb"_s, wantsAddBulb(args)},
    });
    m_view->setSource(QUrl::fromLocalFile(package + u'/' + hostFile));
    if (m_view->status() == QQuickWidget::Error || !m_view->rootObject()) {
        QStringList lines;
        for (const QQmlError &error : m_view->errors()) {
            lines << error.toString();
        }
        delete m_view;
        showMessage((german() ? u"Die Seite ließ sich nicht laden:\n"_s : u"The page did not load:\n"_s) + lines.join(u'\n'));
        return;
    }
    widget()->setFocusProxy(m_view);
    layout->addWidget(m_view);

    connect(this, &KAbstractConfigModule::activationRequested, this, [this](const QVariantList &args) {
        if (m_view && m_view->rootObject() && wantsAddBulb(args)) {
            QMetaObject::invokeMethod(m_view->rootObject(), "requestAddBulb");
        }
    });
}

LichthausKcm::~LichthausKcm()
{
    // The view before its engine.
    delete m_view;
}

void LichthausKcm::showMessage(const QString &text)
{
    auto label = new QLabel(text, widget());
    label->setWordWrap(true);
    label->setAlignment(Qt::AlignCenter);
    label->setTextInteractionFlags(Qt::TextSelectableByMouse);
    widget()->layout()->addWidget(label);
}

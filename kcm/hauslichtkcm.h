// SPDX-License-Identifier: AGPL-3.0-or-later
#pragma once

#include <KCModule>

#include <QPointer>

#include <memory>

class QQmlEngine;
class QQuickWidget;

// One of the widget's Configure pages in System Settings. Which page comes
// from the plugin's metadata (X-HausLicht-Page); see hauslichtkcm.cpp.
class HausLichtKcm : public KCModule
{
    Q_OBJECT
public:
    HausLichtKcm(QObject *parent, const KPluginMetaData &data, const QVariantList &args);
    ~HausLichtKcm() override;

private:
    void showMessage(const QString &text);

    std::unique_ptr<QQmlEngine> m_engine;
    QPointer<QQuickWidget> m_view;
};

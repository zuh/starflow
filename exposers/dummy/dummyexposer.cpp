#include "dummyexposer.h"
#include "reader.h"

#include <QDebug>
#include <QJsonDocument>
#include <QJsonObject>
#include <QUrl>
#include <QTimer>

DummyExposer::DummyExposer(QObject *parent) :
    QObject(parent),
    m_expose(0),
    m_elapsed(0)
{
    qDebug() << "Starting reader";
    connect(&m_reader, &Reader::json, this, &DummyExposer::handleJson);
    m_reader.start();
}

void DummyExposer::handleJson(QJsonDocument doc)
{
    qDebug() << "Handling " << doc.toJson();
    m_expose = new QJsonObject(doc.object());
    if (m_expose->isEmpty()) {
        qWarning() << "Empty JSON doc!";
        return;
    }
    m_elapsed = 0;
    QTimer::singleShot(1000, this, SLOT(doExposure()));
}

void DummyExposer::doExposure()
{
    int seconds = m_expose->value("exposure").toInt();
    m_elapsed++;

    qDebug() << "Exposure: " << m_elapsed << " / " << seconds;

    QTextStream out(stdout);
    QJsonObject exp;
    exp.insert("type", "event");
    exp.insert("event", "exposure");
    exp.insert("duration", seconds);
    exp.insert("elapsed", m_elapsed);
    QJsonDocument doc(exp);
    out << doc.toJson(QJsonDocument::Compact) << endl;

    if (m_elapsed < seconds) {
        QTimer::singleShot(1000, this, SLOT(doExposure()));
        return;
    }

    QJsonObject frame;
    frame.insert("type", "event");
    frame.insert("event", "frame");
    frame.insert("location", "file:///tmp/frame.png");
    doc.setObject(frame);
    out << doc.toJson(QJsonDocument::Compact) << endl;
    out.flush();
}

#ifndef DummyExposer_H
#define DummyExposer_H

#include <QObject>
#include <QJsonDocument>

#include "reader.h"

class DummyExposer : public QObject
{
    Q_OBJECT

public:
    explicit DummyExposer(QObject *parent = 0);

public slots:
    void handleJson(QJsonDocument doc);
    void doExposure();

private:
    Reader m_reader;
    QJsonObject *m_expose;
    int m_elapsed;
};

#endif // DummyExposer_H

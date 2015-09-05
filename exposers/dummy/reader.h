#ifndef READER_H
#define READER_H

#include <QThread>
#include <QJsonDocument>

class Reader : public QThread
{
    Q_OBJECT

public:
    void run() Q_DECL_OVERRIDE;

signals:
    void json(QJsonDocument doc);

};

#endif // READER_H

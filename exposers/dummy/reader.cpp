#include "reader.h"

#include <QDebug>
#include <QJsonDocument>
#include <QTextStream>

void Reader::run()
{
    qDebug() << "Reader starting" << endl;
    QTextStream in(stdin);

    while (true) {
        in.skipWhiteSpace();
        QByteArray line = in.readLine().toUtf8();
        qDebug() << "STR: " << line;
        qDebug() << "empty?: " << line.isEmpty();
        if (in.atEnd())
            break;
        QJsonDocument doc = QJsonDocument::fromJson(line);
        qDebug() << "IN: " << doc;
        if (doc.isArray() || doc.isObject())
            emit json(doc);
    }
    qDebug() << "Reader exiting" << endl;
}

#include <QCoreApplication>

#include "dummyexposer.h"

int main(int argc, char *argv[])
{
    QCoreApplication a(argc, argv);

    DummyExposer dummy(&a);

    return a.exec();
}

#ifndef LIBHAI_H
#define LIBHAI_H

#include <QObject>
#include <QDebug>
#include <QVariant>
#include <QTimer>
#include <stdlib.h>

#ifdef ANDROID
//#include "android/libhai.h"
#elif __linux__
#include "linux/libhai.h"
#elif WIN64
#include "windows/hai.h"
#endif

class Libhai : public QObject
{
    Q_OBJECT
public:
    explicit Libhai(QObject *parent = nullptr);
    ~Libhai();

signals:
    void addressUpdate(QVariant(address));
    void deroUpdate(QVariant deros);
    void tokenUpdate(QVariant token);
    void endWait();

private slots:
    void timeout();
    void waitout();

public slots:
    void getAddress();
    void getBalances();
    bool addrIsRegistered();
    void buy();
    void sell();

    void start();
    void stop();

private:
    QTimer m_timer, m_wait;

};

#endif // LIBHAI_H

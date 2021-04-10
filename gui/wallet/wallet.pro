QT += quick

CONFIG += c++11

# You can make your code fail to compile if it uses deprecated APIs.
# In order to do so, uncomment the following line.
#DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x060000    # disables all the APIs deprecated before Qt 6.0.0

SOURCES += \
        libhai.cpp \
        main.cpp

RESOURCES += qml.qrc

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =

# Additional import path used to resolve QML modules just for Qt Quick Designer
QML_DESIGNER_IMPORT_PATH =

# Default rules for deployment.
qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target

HEADERS += \
    libhai.h

windows: {
HEADERS += \
    windows/hai.h

LIBS += \
        -L$$PWD/windows/ -lhai

INCLUDEPATH += $$PWD/windows
DEPENDPATH += $$PWD/windows
}

unix:!macx:android: {
        HEADERS += \
                android/libsquare.h
        LIBS += \
                -L$$PWD/android -lsquare

        INCLUDEPATH += $$PWD/android
        DEPENDPATH += $$PWD/android
}
unix:!macx:!android: {
        HEADERS += \
                linux/libhai.h
        LIBS += \
                -lpthread \
                -L$$PWD/linux/ -lhai

        INCLUDEPATH += $$PWD/linux
        DEPENDPATH += $$PWD/linux
}

ANDROID_EXTRA_LIBS = $$PWD/android/libhai.so

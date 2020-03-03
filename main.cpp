#include <QGuiApplication>
#include <QQmlContext>
#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlEngine>
#include <QImage>
#include <QObject>
#include <QString>
#include <QTranslator>
#include <QDebug>
#include "MyApi.h"


int main(int argc, char *argv[])
{
	QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
	QGuiApplication::setAttribute(Qt::AA_UseDesktopOpenGL);
	QApplication app(argc, argv);

	QTranslator translator;
	if ( translator.load(QLocale(), QLatin1String("CookieCutter"), QLatin1String("_")) ) {
		app.installTranslator(&translator);
	}
	else {
		qDebug() << "cannot load translation for current locale: '" << QLocale::system().name() << "'... falling back to english version.";
	}

	app.setOrganizationName("NSSS");
	app.setOrganizationDomain("computer-science.de");
	app.setApplicationName("CookieCutter");

	qRegisterMetaType<MyApi>();
	qRegisterMetaType<MyApi*>();
	MyApi callMe{};

	QQmlApplicationEngine		engine{&app};
	engine.rootContext()->setContextProperty("api", &callMe);

	const QUrl url(QStringLiteral("qrc:/main.qml"));
	QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
		&app, [url](QObject* obj, const QUrl& objUrl) {
			if (!obj && url == objUrl)
				QCoreApplication::exit(-1);
		}, Qt::QueuedConnection);

	engine.load(url);
	return app.exec();
}


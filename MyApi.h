#pragma once
#include <QObject>
#include <QImage>
#include <QUrl>
#include <QFile>
#include <QDebug>
#include <QTextStream>
#include <QDir>

#ifdef Q_OS_WIN
#define REMOVE_FILE_PROTOCOL_PREFIX "file:///"
#else
#define REMOVE_FILE_PROTOCOL_PREFIX "file://"
#endif

class MyApi : public QObject
{
	Q_OBJECT
public:
	MyApi():QObject() {};
	MyApi(MyApi const& other) : QObject() {};
	Q_INVOKABLE void saveCookie(QString const& sourcePath, QString const& targetPath, int x, int y, int w, int h, bool rescale = false, int outW = 0, int outH = 0) {
		QString localInPath = sourcePath;
		localInPath.remove(REMOVE_FILE_PROTOCOL_PREFIX);
		QString localOutPath = targetPath;
		localOutPath.remove(REMOVE_FILE_PROTOCOL_PREFIX);
		QImage source(localInPath);
		if (!source.isNull()) {
			QImage cookie = source.copy(x, y ,w, h);
			if (rescale) {
				QImage scaledCookie = cookie.scaled(outW, outH, Qt::IgnoreAspectRatio, Qt::SmoothTransformation);
				scaledCookie.save(localOutPath);
			}
			else {
				cookie.save(localOutPath);
			}
		}
	}

	QString loadCustomCookieShapes() {
		QString	loadedCookieShapesDefinition{};
		QDir	homeDir = QDir::home();
		if (homeDir.mkpath(".config/CookieCutter")) {

			QDir	configDir{ homeDir };
			configDir.cd(".config/CookieCutter");
			QString customCookieShapesDefinitionFilePath = configDir.absoluteFilePath("customCookieShapesDefinition.json");
			QFile	customCookieShapesFile(customCookieShapesDefinitionFilePath);

			if (!customCookieShapesFile.open(QFile::ReadOnly | QFile::Text)) {
				qDebug() << "no custom cookies configuration file found";
			}
			else {
				QTextStream customCookieShapesStream(&customCookieShapesFile);
				customCookieShapesStream.setCodec("UTF-8");
				loadedCookieShapesDefinition = customCookieShapesStream.readAll();
				qDebug() << loadedCookieShapesDefinition;
				customCookieShapesFile.close();
			}
		}
		else {
			qDebug() << "could not create/access config directory path";
		}
		return loadedCookieShapesDefinition;
	}
};
Q_DECLARE_METATYPE(MyApi)
Q_DECLARE_METATYPE(MyApi*)

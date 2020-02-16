#pragma once
#include <QObject>
#include <QImage>
#include <QUrl>

class MyApi : public QObject
{
	Q_OBJECT
public:
	MyApi():QObject() {};
	MyApi(MyApi const& other) : QObject() {};
	Q_INVOKABLE void saveCookie(QString const& sourcePath, QString const& targetPath, int x, int y, int w, int h, bool rescale = false, int outW = 0, int outH = 0) {
		QString localInPath = sourcePath;
		localInPath.remove("file:///");
		QString localOutPath = targetPath;
		localOutPath.remove("file:///");
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
};
Q_DECLARE_METATYPE(MyApi)
Q_DECLARE_METATYPE(MyApi*)

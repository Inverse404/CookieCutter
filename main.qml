import QtQuick 2.13
import QtQuick.Window 2.13
import QtQml 2.13
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.13
//import QtQuick.Dialogs 1.3
import Qt.labs.platform 1.1
import Qt.labs.settings 1.0

ApplicationWindow {
    id: app

	property string currentImageSource:			""
	property double currentCutterScaleFactor:	1.0
	property int	currentCutterScaleAdjust:	0

	property bool	templateSelected:			cutterList.currentIndex != -1
	property int	lastSelectedTemplate:		0
	property double customAspectWidth:			tfCustomWidth.acceptableInput ? parseFloat(tfCustomWidth.text) : 1
	property double customAspectHeight:			tfCustomHeight.acceptableInput ? parseFloat(tfCustomHeight.text) : 1
	property double	currentCookieWidth:			app.templateSelected ? cookieCutters.get(cutterList.currentIndex).initialWidth : customAspectWidth
	property double	currentCookieHeight:		app.templateSelected ? cookieCutters.get(cutterList.currentIndex).initialHeight : customAspectHeight
	property bool	useCustomOutputSize:		swUseCustomOutputSize.checked && tfCustomOutputWidth.acceptableInput && tfCustomOutputHeight.acceptableInput
	property int	customOutputWidth:			tfCustomOutputWidth.acceptableInput ? parseFloat(tfCustomOutputWidth.text) : 1
	property int	customOutputHeight:			tfCustomOutputHeight.acceptableInput ? parseFloat(tfCustomOutputHeight.text) : 1

	property string lastOpenFolder:				""
	property string lastSaveFolder:				""

    visible: true
    title: qsTr("CookieCutter")
	width: 1920 * 0.75
	height: 1080 * 0.75
	minimumHeight: 540
	minimumWidth: 640

	function updateScaleFactorAdjustment() {
		var initialCutterScaleFactor = Math.min(srcImg.width / app.currentCookieWidth / 2, srcImg.height / app.currentCookieHeight / 2); 
		app.currentCutterScaleAdjust = app.currentCookieWidth * initialCutterScaleFactor;
		app.currentCutterScaleFactor = initialCutterScaleFactor;
	}
				
	RowLayout {
		anchors.fill: parent

		Pane {
			id: mainView
			Layout.fillWidth: true
			Layout.fillHeight: true
			padding: 0
			Rectangle {
				anchors.fill: parent
				color: "transparent"
				border.color: "red"
				border.width: 1
				visible: false
			}
			Image {
				id: srcImg
				source: app.currentImageSource
				fillMode: Image.PreserveAspectCrop
				clip: true
				property bool showSelectionMask: true
				
				property double heightFitFactor: parent.height / sourceSize.height
				property double widthFitFactor: parent.width / sourceSize.width
				property bool	fitHeight: heightFitFactor < widthFitFactor
				property bool	fitWidth: heightFitFactor > widthFitFactor
				property double fitScaleFactor: Math.min(heightFitFactor, widthFitFactor)
				property double maxScaleW: srcImg.width / app.currentCookieWidth
				property double maxScaleH: srcImg.height / app.currentCookieHeight

				x: mainView.width - width <= 0 ? 0 : (mainView.width - width) / 2
				y: mainView.height - height <= 0 ? 0 : (mainView.height - height) / 2
				
				height: fitScaleFactor * sourceSize.height
				width:fitScaleFactor *  sourceSize.width

				onWidthChanged: {
					if(status == Image.Ready) {
						cutterList.onCurrentIndexChanged();
					}
				}
				onHeightChanged: {
					onWidthChanged();
				}
				

				MouseArea {
					id: ma
					anchors.fill: parent
					hoverEnabled: true
					acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
					onWheel: {
						var scaleAdjustmentChange = wheel.angleDelta.y / 120;
						var newScaleAdjustment = 0.0;

						if (wheel.modifiers & Qt.ShiftModifier) {
							if (scaleAdjustmentChange > 0) {
								newScaleAdjustment = 1.0;
							}
							else {
								newScaleAdjustment = -1.0;
							}
						}
						else {
							newScaleAdjustment = scaleAdjustmentChange * (Math.max(mainView.height, mainView.width) / 40);
						}

						app.currentCutterScaleAdjust += newScaleAdjustment;
						var newScaleFactor = (app.currentCookieWidth + app.currentCutterScaleAdjust) / app.currentCookieWidth;

						if (newScaleFactor < 1.0) {
							newScaleFactor = 1.0;
						}
						
						app.currentCutterScaleFactor = Math.min(newScaleFactor, srcImg.maxScaleW, srcImg.maxScaleH); 
					}
					onClicked: {
						if (mouse.button == Qt.MiddleButton) {
							app.updateScaleFactorAdjustment();
						}
						if (mouse.button == Qt.LeftButton) {
							var cookieX = srcImg.sourceSize.width / (srcImg.width / cookieCutter.x);
							var cookieY = srcImg.sourceSize.height / (srcImg.height / cookieCutter.y);
							var cookieW = srcImg.sourceSize.width / (srcImg.width / cookieCutter.width);
							var cookieH = srcImg.sourceSize.height / (srcImg.height / cookieCutter.height);
							if (cookieX + cookieW > srcImg.sourceSize.width) {
								cookieW = srcImg.sourceSize.width - cookieX;
							}
							if (cookieY + cookieH > srcImg.sourceSize.height) {
								cookieH = srcImg.sourceSize.height - cookieY;
							}
							saveDialog.cookieX = cookieX;
							saveDialog.cookieY = cookieY;
							saveDialog.cookieW = cookieW;
							saveDialog.cookieH = cookieH;

							var sourceFilenameExtensionIndex = app.currentImageSource.lastIndexOf(".");
							var sourceFilepathDirectoryEndIndex = app.currentImageSource.lastIndexOf("/");
							var sourceFilenameWithoutExtension = app.currentImageSource.substring(sourceFilepathDirectoryEndIndex + 1, sourceFilenameExtensionIndex);
							var sourceFileExtension = app.currentImageSource.substring(sourceFilenameExtensionIndex);
							var suggestedSaveFileName = "file://" + sourceFilenameWithoutExtension + "_" + app.currentCookieWidth + "x" + app.currentCookieHeight + sourceFileExtension;
							saveDialog.currentFile = suggestedSaveFileName;
							saveDialog.folder = app.lastSaveFolder;
							saveDialog.open();
						}
					}
				}
				Rectangle {
					id: cookieCutter

					width: Math.round(app.currentCookieWidth * app.currentCutterScaleFactor)
					height: Math.round(app.currentCookieHeight * app.currentCutterScaleFactor)

					color: "red"
					opacity: 0.5
					visible: false

					property int horizontalPadding: width / 2
					property int verticalPadding: height / 2
					property int unclampedX: ma.mouseX - horizontalPadding
					property int unclampedY: ma.mouseY - verticalPadding
					x: Math.max(0, Math.min(unclampedX, parent.width - width))
					y: Math.max(0, Math.min(unclampedY, parent.height - height))
				}
				Rectangle {
					visible: srcImg.showSelectionMask

					anchors.left: srcImg.left
					anchors.right: cookieCutter.left
					anchors.top: srcImg.top
					anchors.bottom: srcImg.bottom
					color: "blue"
					opacity: 0.5
				}
				Rectangle {
					visible: srcImg.showSelectionMask

					anchors.right: srcImg.right
					anchors.left: cookieCutter.right
					anchors.top: srcImg.top
					anchors.bottom: srcImg.bottom
					color: "blue"
					opacity: 0.5
				}
				Rectangle {
					visible: srcImg.showSelectionMask

					anchors.left: cookieCutter.left
					anchors.right: cookieCutter.right
					anchors.top: srcImg.top
					anchors.bottom: cookieCutter.top
					color: "blue"
					opacity: 0.5
				}
				Rectangle {
					visible: srcImg.showSelectionMask

					anchors.left: cookieCutter.left
					anchors.right: cookieCutter.right
					anchors.top: cookieCutter.bottom
					anchors.bottom: srcImg.bottom
					color: "blue"
					opacity: 0.5
				}
			}
			clip:	true

		}
		ColumnLayout {
			Layout.fillHeight: true
			Layout.preferredWidth: 250
			Layout.maximumWidth: Layout.preferredWidth
			spacing: 5

			Item {
				Layout.topMargin: 15
				Layout.fillWidth: true
				height:				childrenRect.height
				width:				childrenRect.width
				Image {
					source:			"qrc:/logo.png"
					width:			235
					height:			60
					fillMode:		Image.PreserveAspectCrop
					Button {
						icon.source:	"qrc:/help-24px.svg"
						text:			"info"
						anchors.right:	parent.right
						anchors.bottom:	parent.bottom
						anchors.rightMargin: 5
						onClicked: {
							infoPopup.open();
						}
					}
				}
			}
			Button {
				Layout.topMargin: 15
				Layout.bottomMargin: 15
				text: "Pick input image..."
				onClicked: {
					pickSourceDialog.folder = app.lastOpenFolder;
					pickSourceDialog.open();
				}
			}
			Label {
				text: "Cookie shapes (" + cookieCutters.count + ")"
				font.bold: true
			}
			ListView {
				Layout.topMargin: 15
				id: cutterList
				Layout.preferredWidth: 250
				Layout.minimumHeight: 100
				Layout.fillHeight: true
				currentIndex: 0
				highlight: highlight
				clip: true
				enabled: swUseCustomAspect.checked == false
				ScrollBar.vertical: 
					ScrollBar {
						id: sbCookieList
						policy:	ScrollBar.AlwaysOn
					}

				onCurrentIndexChanged: {
					if (currentIndex != -1) {
						swUseCustomAspect.checked = false;
					}
					app.updateScaleFactorAdjustment();
				}

				delegate:
					ItemDelegate {
						id: cutterDel
						text: name + " (" + initialWidth + ":" + initialHeight + ")"
						width: cutterList.width - sbCookieList.width
						onClicked: {
							cutterList.currentIndex = index;
							app.updateScaleFactorAdjustment();
						}
					}
				model:
					ListModel {
						id: cookieCutters

						ListElement {
							name: "golden cut"
							initialWidth: 1.0
							initialHeight: 1.618
						}
						ListElement {
							name: "Square"
							initialWidth: 1.0
							initialHeight: 1.0
						}
						ListElement {
							name: "Univisium"
							initialWidth: 2.0
							initialHeight: 1.0
						}
						ListElement {
							name: "35mm film"
							initialWidth: 3.0
							initialHeight: 2.0
						}
						ListElement {
							name: "APS-Panorama"
							initialWidth: 3.0
							initialHeight: 1.0
						}
						ListElement {
							name: "legacy photo"
							initialWidth: 5.0
							initialHeight: 4.0
						}
						ListElement {
							name: "legacy screen"
							initialWidth: 4.0
							initialHeight: 3.0
						}
						ListElement {
							name: "digital screen"
							initialWidth: 16.0
							initialHeight: 9.0
						}
						ListElement {
							name: "digital screen"
							initialWidth: 16.0
							initialHeight: 10.0
						}
						ListElement {
							name: "mobile screen portrait"
							initialWidth: 9.0
							initialHeight: 16.0
						}
						ListElement {
							name: "widescreen film"
							initialWidth: 1.85
							initialHeight: 1.0
						}
						ListElement {
							name: "anamorphic film"
							initialWidth: 2.35
							initialHeight: 1.0
						}
						ListElement {
							name: "anamorphic film"
							initialWidth: 2.39
							initialHeight: 1.0
						}
						ListElement {
							name: "ultra panavision film"
							initialWidth: 2.75
							initialHeight: 1.0
						}
						ListElement {
							name: "polyvision film"
							initialWidth: 4.0
							initialHeight: 1.0
						}
					}
			}
			RowLayout {
				Layout.topMargin: 15
				Layout.fillWidth: true
				Switch {
					id: swUseCustomAspect
					onCheckedChanged: {
						if (checked) {
							app.lastSelectedTemplate = cutterList.currentIndex;
							cutterList.currentIndex = -1;
							app.updateScaleFactorAdjustment();
						}
						else {
							cutterList.currentIndex = app.lastSelectedTemplate;
							app.updateScaleFactorAdjustment();
						}
					}
					onEnabledChanged: {
						if (!enabled) {
							checked = false;
						}
					}
					enabled: tfCustomWidth.acceptableInput && tfCustomHeight.acceptableInput
				}
				Label {
					text:		"custom aspect ratio"
					font.bold:	true
				}
			}
			RowLayout {
				Layout.fillWidth: true
				Rectangle {
					width: 10
					height: 10
					color: tfCustomWidth.acceptableInput && tfCustomHeight.acceptableInput ? "green" : "red"
				}
				TextField {
					selectByMouse: true
					id: tfCustomWidth
					Layout.preferredWidth:	60
					validator:
						DoubleValidator {
							bottom: 0.0
							decimals: 5
						}
					placeholderText: "width"
				}
				Label {
					text: ":"
				}
				TextField {
					selectByMouse: true
					id: tfCustomHeight
					Layout.preferredWidth:	tfCustomWidth.width
					validator:
						DoubleValidator {
							bottom: 0.0
							decimals: 5
						}
					placeholderText: "height"
				}
			}
			RowLayout {
				Layout.topMargin: 15
				Layout.fillWidth: true
				Switch {
					id: swUseCustomOutputSize
					onEnabledChanged: {
						if (!enabled) {
							checked = false;
						}
					}
					enabled: tfCustomOutputWidth.acceptableInput && tfCustomOutputHeight.acceptableInput
				}
				Label {
					text: "custom output size"
					font.bold: true
				}
			}
			RowLayout {
				Layout.fillWidth: true
				
				Rectangle {
					width: 10
					height: 10
					color: tfCustomOutputWidth.acceptableInput && tfCustomOutputHeight.acceptableInput ? "green" : "red"
				}
				TextField {
					selectByMouse: true
					id: tfCustomOutputWidth
					Layout.preferredWidth:	60
					validator:
						DoubleValidator {
							bottom: 0.0
							decimals: 5
						}
					placeholderText: "width"
				}
				Label {
					text: " * "
				}
				TextField {
					id: tfCustomOutputHeight
					selectByMouse: true
					Layout.preferredWidth:	tfCustomWidth.width
					validator:
						DoubleValidator {
							bottom: 0.0
							decimals: 5
						}
					placeholderText: "height"
				}
				Label {
					text: "pixels"
				}
			}
			Item {
				height: 30
				width: 1
			}
		}
	}
	FileDialog {
		id: pickSourceDialog
		nameFilters: ["Images (*.jpg *.jpeg *.png *.bmp)"]
		fileMode:	FileDialog.OpenFile
		onAccepted: {
			app.currentImageSource = file;
			app.lastOpenFolder = folder;
		}
	}
	FileDialog {
		id: saveDialog
		nameFilters: ["Images (*.jpg *.jpeg *.png *.bmp)"]
		fileMode:	FileDialog.SaveFile
		defaultSuffix: "jpg"
		property double cookieX: 0;
		property double cookieY: 0;
		property double cookieW: 0;
		property double cookieH: 0;
		onAccepted: {
			api.saveCookie(app.currentImageSource, file, cookieX, cookieY, cookieW, cookieH, app.useCustomOutputSize, app.customOutputWidth, app.customOutputHeight);
			app.lastSaveFolder = folder;
		}
	}
	Popup {
		id: infoPopup
		anchors.centerIn: parent

		ScrollView {
			anchors.fill: parent
			ColumnLayout {
				Label {
					text:			"CookieCutter - quick image cut outs"
					font.pointSize:	16
					font.bold:		true
				}
				Label {
					text:	"(c) 2020 Niels Sönke Seidler\n\nThis software is licensed under the GPL v3\n(see included file 'gpl-3.0.txt' or 'http://https://www.gnu.org/licenses/gpl-3.0')"
				}
			}
		}
	}
	Component {
		id: highlight
		Rectangle {
			width: cutterList.width; height: 40
			color: "lightsteelblue"; radius: 5
			y: cutterList.currentIndex != -1 ? cutterList.currentItem.y : 0
			Behavior on y {
				SpringAnimation {
					spring: 3
					damping: 0.2
				}
			}
		}
	}
	Settings {
		property alias	customOutputWidth:		tfCustomOutputWidth.text
		property alias	customOutputHeight:		tfCustomOutputHeight.text
		property alias	useCustomOutputSize:	swUseCustomOutputSize.checked

		property alias	customAspectWidth:		tfCustomWidth.text
		property alias	customAspectHeight:		tfCustomHeight.text

		property alias	windowWidth:			app.width
		property alias	widnowHeight:			app.height
		property alias	windowPosX:				app.x
		property alias	widnowPosY:				app.y
	}
}


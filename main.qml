import QtQuick 2.14
import QtQuick.Window 2.14
import QtQml 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.4
import QtQuick.Controls.Material 2.14
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

	visible:		true
	title:			qsTr("CookieCutter")
	width:			1920 * 0.75
	height:			1080 * 0.75
	minimumHeight:	540
	minimumWidth:	640

	Component.onCompleted: {
		if (customCookieShapesDefinition != "") {
			var parsedCustomCookieShapes = JSON.parse(customCookieShapesDefinition);
			if (Array.isArray(parsedCustomCookieShapes)) {
				parsedCustomCookieShapes.forEach(addToCookieCutterList);
			}
			cutterList.currentIndex = 0;
		}
	}

	function addToCookieCutterList(item, index) {
		if (item.hasOwnProperty("name")
			&& item.hasOwnProperty("initialWidth")
			&& item.hasOwnProperty("initialHeight")
			&& item.hasOwnProperty("source")	
			){
			cookieCutters.insert(0, {"name": item.name, "initialWidth": item.initialWidth, "initialHeight": item.initialHeight, "source": item.source});
		}
	}
	
	function updateScaleFactorAdjustment() {
		var initialCutterScaleFactor = Math.min(srcImg.width / app.currentCookieWidth / 2, srcImg.height / app.currentCookieHeight / 2); 
		app.currentCutterScaleAdjust = app.currentCookieWidth * initialCutterScaleFactor;
		app.currentCutterScaleFactor = initialCutterScaleFactor;
	}
				
	RowLayout {
		anchors.fill: parent

		Pane {
			id: mainView

			Layout.fillWidth:	true
			Layout.fillHeight:	true
			padding:			0
			clip:				true

			Rectangle {
				anchors.fill:	parent
				color:			"transparent"
				border.color:	"red"
				border.width:	1
				visible:		false
			}

			Image {
				id: srcImg

				property bool	showSelectionMask:	true
				property double heightFitFactor:	parent.height / sourceSize.height
				property double widthFitFactor:		parent.width / sourceSize.width
				property bool	fitHeight:			heightFitFactor < widthFitFactor
				property bool	fitWidth:			heightFitFactor > widthFitFactor
				property double fitScaleFactor:		Math.min(heightFitFactor, widthFitFactor)
				property double maxScaleW:			srcImg.width / app.currentCookieWidth
				property double maxScaleH:			srcImg.height / app.currentCookieHeight

				source:		app.currentImageSource
				fillMode:	Image.PreserveAspectCrop
				clip:		true
				x:			mainView.width - width <= 0 ? 0 : (mainView.width - width) / 2
				y:			mainView.height - height <= 0 ? 0 : (mainView.height - height) / 2
				height:		fitScaleFactor * sourceSize.height
				width:		fitScaleFactor *  sourceSize.width

				onWidthChanged: {
					if(status == Image.Ready) {
						cutterList.onCurrentIndexChanged();
					}
				}//onWidthChanged

				onHeightChanged: {
					onWidthChanged();
				}

				MouseArea {
					id: ma

					anchors.fill:		parent
					hoverEnabled:		true
					acceptedButtons:	Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

					onWheel: {
						var scaleAdjustmentChange	= wheel.angleDelta.y / 120;
						var newScaleAdjustment		= 0.0;

						if (wheel.modifiers & Qt.ShiftModifier) {
							if (scaleAdjustmentChange > 0) {
								newScaleAdjustment = 1.0;
							}
							else {
								newScaleAdjustment = -1.0;
							}
						}//if (wheel.modifiers & Qt.ShiftModifier)
						else {
							newScaleAdjustment = scaleAdjustmentChange * (Math.max(mainView.height, mainView.width) / 40);
						}

						app.currentCutterScaleAdjust += newScaleAdjustment;
						var newScaleFactor = (app.currentCookieWidth + app.currentCutterScaleAdjust) / app.currentCookieWidth;

						if (newScaleFactor < 1.0) {
							newScaleFactor = 1.0;
						}
						
						app.currentCutterScaleFactor = Math.min(newScaleFactor, srcImg.maxScaleW, srcImg.maxScaleH); 
					}//onWheel

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

							var sourceFilenameExtensionIndex		= app.currentImageSource.lastIndexOf(".");
							var sourceFilepathDirectoryEndIndex		= app.currentImageSource.lastIndexOf("/");
							var sourceFilenameWithoutExtension		= app.currentImageSource.substring(sourceFilepathDirectoryEndIndex + 1, sourceFilenameExtensionIndex);
							var sourceFileExtension					= app.currentImageSource.substring(sourceFilenameExtensionIndex);
							var suggestedSaveFileName				= "file://" + sourceFilenameWithoutExtension + "_" + app.currentCookieWidth + "x" + app.currentCookieHeight + sourceFileExtension;
							saveDialog.currentFile					= suggestedSaveFileName;
							saveDialog.folder						= app.lastSaveFolder;
							saveDialog.open();
						}//if (mouse.button == Qt.LeftButton)
					}//onClicked
				}//MouseArea

				Rectangle {
					id: cookieCutter

					property int horizontalPadding: width / 2
					property int verticalPadding:	height / 2
					property int unclampedX:		ma.mouseX - horizontalPadding
					property int unclampedY:		ma.mouseY - verticalPadding

					x:			Math.max(0, Math.min(unclampedX, parent.width - width))
					y:			Math.max(0, Math.min(unclampedY, parent.height - height))
					width:		Math.round(app.currentCookieWidth * app.currentCutterScaleFactor)
					height:		Math.round(app.currentCookieHeight * app.currentCutterScaleFactor)
					color:		"red"
					opacity:	0.5
					visible:	false
				}

				Rectangle {
					visible:		srcImg.showSelectionMask
					anchors.left:	srcImg.left
					anchors.right:	cookieCutter.left
					anchors.top:	srcImg.top
					anchors.bottom:	srcImg.bottom
					color:			"blue"
					opacity:		0.5
				}

				Rectangle {
					visible:		srcImg.showSelectionMask
					anchors.right:	srcImg.right
					anchors.left:	cookieCutter.right
					anchors.top:	srcImg.top
					anchors.bottom:	srcImg.bottom
					color:			"blue"
					opacity:		0.5
				}

				Rectangle {
					visible:		srcImg.showSelectionMask
					anchors.left:	cookieCutter.left
					anchors.right:	cookieCutter.right
					anchors.top:	srcImg.top
					anchors.bottom:	cookieCutter.top
					color:			"blue"
					opacity:		0.5
				}

				Rectangle {
					visible:		srcImg.showSelectionMask
					anchors.left:	cookieCutter.left
					anchors.right:	cookieCutter.right
					anchors.top:	cookieCutter.bottom
					anchors.bottom:	srcImg.bottom
					color:			"blue"
					opacity:		0.5
				}
			}//Image
		}//Pane

		ColumnLayout {
			id: clSideMenu

			Layout.fillHeight:		true
			Layout.preferredWidth:	250
			Layout.maximumWidth:	Layout.preferredWidth
			spacing:				5

			Item {
				Layout.topMargin:	15
				Layout.fillWidth:	true
				height:				childrenRect.height
				width:				childrenRect.width

				Image {
					source:			"qrc:/logo.png"
					width:			235
					height:			60
					fillMode:		Image.PreserveAspectCrop

					Button {
						icon.source:			"qrc:/help-24px.svg"
						text:					qsTr("info")
						anchors.right:			parent.right
						anchors.bottom:			parent.bottom
						anchors.rightMargin:	5

						onClicked: {
							infoPopup.open();
						}
					}//Button
				}//Image
			}//Item

			Button {
				id: btnPickSourceImage

				Layout.topMargin:		15
				Layout.bottomMargin:	15
				text:					qsTr("pick input image...")

				onClicked: {
					pickSourceDialog.folder = app.lastOpenFolder;
					pickSourceDialog.open();
				}
			}//Button

			Label {
				text:		qsTr("cookie shapes (%1)").arg(cookieCutters.count)
				font.bold:	true
			}

			ListView {
				id: cutterList

				Layout.topMargin:		15
				Layout.preferredWidth:	250
				Layout.minimumHeight:	100
				Layout.fillHeight:		true
				currentIndex:			0
				highlight:				highlight
				clip:					true
				enabled:				swUseCustomAspect.checked == false

				ScrollBar.vertical: 
					ScrollBar {
						id: sbCookieList

						policy:		ScrollBar.AlwaysOn
					}

				onCurrentIndexChanged: {
					if (currentIndex != -1) {
						swUseCustomAspect.checked = false;
					}
					app.updateScaleFactorAdjustment();
				}//onCurrentIndexChanged

				delegate:
					ItemDelegate {
						id: cutterDel

						text:	qsTr(cookieCutters.get(index).name) + qsTr(" (%L1:%L2)" ).arg(initialWidth).arg(initialHeight)
						width:	cutterList.width - sbCookieList.width

						onClicked: {
							cutterList.currentIndex = index;
							app.updateScaleFactorAdjustment();
						}
					}//ItemDelegate

				section.property:			"source"
				section.labelPositioning:	ViewSection.InlineLabels | ViewSection.CurrentLabelAtStart

				section.delegate:
					ItemDelegate {
						id: sectionDel

						text:		qsTr(section)
						width:		cutterList.width - sbCookieList.width
						font.bold:	true

						background:
							Rectangle {
								anchors.fill:	parent
								color:			Material.background

								Rectangle {
									width:			parent.width
									height:			1
									anchors.bottom:	parent.bottom
								}
							}//Rectangle
					}//ItemDelegate

				model:
					ListModel {
						id: cookieCutters

						ListElement {
							name:			QT_TR_NOOP("golden cut")
							initialWidth:	1.0
							initialHeight:	1.618
							source:			QT_TR_NOOP("standard cookies")
						}

						ListElement {
							name:			QT_TR_NOOP("square")
							initialWidth:	1.0
							initialHeight:	1.0
							source:			QT_TR_NOOP("standard cookies")
						}

						ListElement {
							name:			QT_TR_NOOP("univisium")
							initialWidth:	2.0
							initialHeight:	1.0
							source:			QT_TR_NOOP("standard cookies")
						}

						ListElement {
							name:			QT_TR_NOOP("35mm film")
							initialWidth:	3.0
							initialHeight:	2.0
							source:			QT_TR_NOOP("standard cookies")
						}

						ListElement {
							name:			QT_TR_NOOP("APS Panorama")
							initialWidth:	3.0
							initialHeight:	1.0
							source:			QT_TR_NOOP("standard cookies")
						}

						ListElement {
							name:			QT_TR_NOOP("legacy photo")
							initialWidth:	5.0
							initialHeight:	4.0
							source:			QT_TR_NOOP("standard cookies")
						}

						ListElement {
							name:			QT_TR_NOOP("legacy screen")
							initialWidth:	4.0
							initialHeight:	3.0
							source:			QT_TR_NOOP("standard cookies")
						}

						ListElement {
							name:			QT_TR_NOOP("digital screen")
							initialWidth:	16.0
							initialHeight:	9.0
							source:			QT_TR_NOOP("standard cookies")
						}

						ListElement {
							name:			QT_TR_NOOP("digital screen")
							initialWidth:	16.0
							initialHeight:	10.0
							source:			QT_TR_NOOP("standard cookies")
						}

						ListElement {
							name:			QT_TR_NOOP("mobile screen portrait")
							initialWidth:	9.0
							initialHeight:	16.0
							source:			QT_TR_NOOP("standard cookies")
						}

						ListElement {
							name:			QT_TR_NOOP("widescreen film")
							initialWidth:	1.85
							initialHeight:	1.0
							source:			QT_TR_NOOP("standard cookies")
						}

						ListElement {
							name:			QT_TR_NOOP("anamorphic film")
							initialWidth:	2.35
							initialHeight:	1.0
							source:			QT_TR_NOOP("standard cookies")
						}

						ListElement {
							name:			QT_TR_NOOP("anamorphic film")
							initialWidth:	2.39
							initialHeight:	1.0
							source:			QT_TR_NOOP("standard cookies")
						}

						ListElement {
							name:			QT_TR_NOOP("ultra panavision film")
							initialWidth:	2.75
							initialHeight:	1.0
							source:			QT_TR_NOOP("standard cookies")
						}

						ListElement {
							name:			QT_TR_NOOP("polyvision film")
							initialWidth:	4.0
							initialHeight:	1.0
							source:			QT_TR_NOOP("standard cookies")
						}
					}//ListModel
			}//ListView

			RowLayout {
				Layout.topMargin:	15
				Layout.fillWidth:	true

				Switch {
					id: swUseCustomAspect

					enabled:	tfCustomWidth.acceptableInput && tfCustomHeight.acceptableInput

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
					}//onCheckedChanged

					onEnabledChanged: {
						if (!enabled) {
							checked = false;
						}
					}//onEnabledChanged
				}//Switch

				Label {
					text:		qsTr("custom aspect ratio")
					font.bold:	true
				}
			}
			RowLayout {
				Layout.fillWidth:	true

				Rectangle {
					width:	10
					height:	10
					color:	tfCustomWidth.acceptableInput && tfCustomHeight.acceptableInput ? "green" : "red"
				}

				TextField {
					id: tfCustomWidth

					selectByMouse:			true
					Layout.preferredWidth:	60
					placeholderText:		qsTr("width")

					validator:
						DoubleValidator {
							bottom: 0.0
							decimals: 5
						}

				}//TextField

				Label {
					text: ":"
				}

				TextField {
					id: tfCustomHeight

					selectByMouse:			true
					Layout.preferredWidth:	tfCustomWidth.width
					placeholderText:		qsTr("height")

					validator:
						DoubleValidator {
							bottom: 0.0
							decimals: 5
						}
				}//TextField
			}//RowLayout

			RowLayout {
				Layout.topMargin:	15
				Layout.fillWidth:	true

				Switch {
					id: swUseCustomOutputSize

					enabled:	tfCustomOutputWidth.acceptableInput && tfCustomOutputHeight.acceptableInput

					onEnabledChanged: {
						if (!enabled) {
							checked = false;
						}
					}//onEnabledChanged
				}//Switch

				Label {
					text:		qsTr("custom output size")
					font.bold:	true
				}
			}//RowLayout

			RowLayout {
				Layout.fillWidth:	true
				
				Rectangle {
					width:	10
					height:	10
					color:	tfCustomOutputWidth.acceptableInput && tfCustomOutputHeight.acceptableInput ? "green" : "red"
				}

				TextField {
					id: tfCustomOutputWidth

					selectByMouse:			true
					Layout.preferredWidth:	60
					placeholderText:		qsTr("width")

					validator:
						DoubleValidator {
							bottom: 0.0
							decimals: 5
						}
				}//TextField

				Label {
					text: " * "
				}

				TextField {
					id: tfCustomOutputHeight

					selectByMouse:			true
					Layout.preferredWidth:	tfCustomWidth.width
					placeholderText:		qsTr("height")

					validator:
						DoubleValidator {
							bottom: 0.0
							decimals: 5
						}
				}//TextField

				Label {
					text:	qsTr("pixels")
				}
			}//RowLayout

			Item {
				height: 30
				width: 1
			}
		}//ColumnLayout
	}//RowLayout

	FileDialog {
		id: pickSourceDialog

		nameFilters:	[qsTr("Images (*.jpg *.jpeg *.png *.bmp)")]
		fileMode:		FileDialog.OpenFile

		onAccepted: {
			app.currentImageSource	= file;
			app.lastOpenFolder		= folder;
		}
	}//FileDialog

	FileDialog {
		id: saveDialog

		property double cookieX:	0;
		property double cookieY:	0;
		property double cookieW:	0;
		property double cookieH:	0;

		nameFilters:	[qsTr("Images (*.jpg *.jpeg *.png *.bmp)")]
		fileMode:		FileDialog.SaveFile
		defaultSuffix:	"jpg"

		onAccepted: {
			api.saveCookie(app.currentImageSource, file, cookieX, cookieY, cookieW, cookieH, app.useCustomOutputSize, app.customOutputWidth, app.customOutputHeight);
			app.lastSaveFolder = folder;
		}
	}//FileDialog

	Popup {
		id: infoPopup

		anchors.centerIn:	parent

		ScrollView {
			anchors.fill:	parent

			ColumnLayout {

				Label {
					text:			qsTr("CookieCutter - quick image cut outs")
					font.pointSize:	16
					font.bold:		true
				}

				Label {
					text:	qsTr("(c) 2020 Niels Sönke Seidler\n\nThis software is licensed under the GPL v3\n(see included file 'gpl-3.0.txt' or 'http://https://www.gnu.org/licenses/gpl-3.0')")
				}
			}//ColumnLayout
		}//ScrollView
	}//Popup

	Component {
		id: highlight

		Rectangle {
			width:	cutterList.width
			height:	40
			color:	"lightsteelblue"
			radius: 5
			y:		cutterList.currentIndex != -1 ? cutterList.currentItem.y : 0

			Behavior on y {
				SpringAnimation {
					spring: 3
					damping: 0.2
				}
			}//Behavior on y
		}//Rectangle
	}//Component

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

// Tutorial popups

	Popup {
		id: popHint01

		y:			(btnPickSourceImage.y + btnPickSourceImage.height / 2) - height / 2
		x:			clSideMenu.x - 15 - width
		visible:	true
		clip:		true

		RowLayout {
			spacing:	0
			anchors.fill:	parent

			Label {
				text:				qsTr("Step 1: Pick a source image to cut pieces from.")
				wrapMode:			Text.Wrap
				Layout.fillWidth:	true
			}

			ToolButton {
				icon.source:	"qrc:/arrow_forward-24px.svg"
				padding:		0
			}
		}//RowLayout
	}//Popup

	Popup {
		id: popHint02

		y:			cutterList.y
		x:			clSideMenu.x - 15 - width
		visible:	true
		clip:		true

		RowLayout {
			spacing:	0
			anchors.fill:	parent

			Label {
				text:				qsTr("Step 2: Choose a cookie cutout shape.")
				wrapMode:			Text.Wrap
				Layout.fillWidth:	true
			}

			ToolButton {
				icon.source:	"qrc:/arrow_forward-24px.svg"
				padding:		0
			}
		}//RowLayout
	}//Popup

	Popup {
		id: popHint03

		y:			cutterList.y + 80
		x:			clSideMenu.x - 15 - width
		visible:	true
		clip:		true
		width:		Math.min(btnStep3.implicitWidth + lblStep3.implicitWidth + 30, clSideMenu.x ) - 15;

		RowLayout {
			spacing:	0
			anchors.fill:	parent

			ToolButton {
				id: btnStep3

				icon.source:	"qrc:/arrow_back-24px.svg"
				padding:		0
			}

			Label {
				id: lblStep3

				text:				qsTr("Step 3: Move mouse over the source image to aim.")
				wrapMode:			Text.Wrap
				Layout.fillWidth:	true
			}
		}//RowLayout
	}//Popup

	Popup {
		id: popHint04

		y:			cutterList.y + 160
		x:			clSideMenu.x - 15 - width
		visible:	true
		clip:		true
		width:		Math.min(btnStep4.implicitWidth + Math.max(lblStep4a.implicitWidth, lblStep4b.implicitWidth) + 30, clSideMenu.x ) - 15;

		RowLayout {
			spacing:	0
			anchors.fill:	parent

			ToolButton {
				id: btnStep4

				icon.source:	"qrc:/arrow_back-24px.svg"
				padding:		0
			}

			ColumnLayout {
				Label {
					id: lblStep4a

					text:				qsTr("Step 4: Use mouse wheel to change cutout size.")
					wrapMode:			Text.Wrap
					Layout.fillWidth:	true
				}
				Label {
					id: lblStep4b

					text:				qsTr("Hold shift while turning the mouse wheel for higher precision.")
					wrapMode:			Text.Wrap
					Layout.fillWidth:	true
				}
			}
		}//RowLayout
	}//Popup

	Popup {
		id: popHint05

		y:			cutterList.y + 255
		x:			clSideMenu.x - 15 - width
		visible:	true
		clip:		true
		width:		Math.min(btnStep5.implicitWidth + lblStep5.implicitWidth + 30, clSideMenu.x ) - 15;

		RowLayout {
			spacing:		0
			anchors.fill:	parent

			ToolButton {
				id: btnStep5

				icon.source:	"qrc:/arrow_back-24px.svg"
				padding:		0
			}

			Label {
				id: lblStep5

				text:		qsTr("Step 5: Click at the desired position to save your cutout to a new file.")
				wrapMode:	Text.Wrap
				Layout.fillWidth: true
			}
		}//RowLayout
	}//Popup
}//ApplicationWindow


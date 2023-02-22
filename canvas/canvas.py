from PyQt5.QtCore import pyqtProperty, pyqtSlot, pyqtSignal, QObject, Qt, QPointF, QPoint, QSize, QRectF, QTimer
from PyQt5.QtQuick import QQuickFramebufferObject
from PyQt5.QtGui import QColor, QPainter, QImage, QGuiApplication
from PyQt5.QtQml import qmlRegisterType, qmlRegisterUncreatableType
import math

from canvas.renderer import *
from canvas.shared import *

class CanvasBrush(QObject):
    updated = pyqtSignal()
    def __init__(self, parent=None):
        super().__init__(parent)
        self._color = QColor()
        self._size = 100
        self._spacing = 0.1
        self._hardness = 0.5
        self._opacity = 1.0
        self.setColor(QColor())
        self.updated.emit()

    def setColor(self, color):
        self._color = QColor(color)
        self._opacity = self._color.alphaF()
        self._color.setAlphaF(1.0)

    def getAbsoluteSpacing(self):
        return self._size * self._spacing

    def getColor(self, radius):
        hardness = (self._hardness + 0.2)/1.2
        alpha = 1.0
        if self._hardness != 1:
            if self._hardness >= 0.5:
                h = 1/(hardness) - 1
                alpha = ((math.cos(radius*math.pi)+1)/2)**h
            else:
                h = 1/(1-hardness) - 1
                alpha = 1-(((math.cos((radius+1)*math.pi)+1)/2))**h

        color = QColor(self._color)
        color.setAlphaF(alpha)
        return color

    @pyqtProperty(QColor, notify=updated)
    def color(self):
        return self._color
    
    @color.setter
    def color(self, color):
        self.setColor(color)
        self.updated.emit()

    @pyqtProperty(float, notify=updated)
    def size(self):
        return self._size
    
    @size.setter
    def size(self, size):
        self._size = size
        self.updated.emit()

    @pyqtProperty(float, notify=updated)
    def hardness(self):
        return self._hardness
    
    @hardness.setter
    def hardness(self, hardness):
        self._hardness = hardness
        self.updated.emit()

    @pyqtProperty(float, notify=updated)
    def spacing(self):
        return self._spacing
    
    @spacing.setter
    def spacing(self, spacing):
        self._spacing = spacing
        self.updated.emit()

    @pyqtProperty(float, notify=updated)
    def opacity(self):
        return self._opacity
    
    @opacity.setter
    def opacity(self, opacity):
        self._opacity = opacity
        self.updated.emit()

class CanvasLayer(QObject):
    updated = pyqtSignal()
    index = 0
    def __init__(self, name, size, parent=None):
        super().__init__(parent)
        self._name = name
        self._thumbnail = QImage()
        self._opacity = 1.0
        self._mode = QPainter.CompositionMode_SourceOver
        self._size = size
        self._visible = True
        self._offset = QPoint(0,0)
        self._index = CanvasLayer.index
        CanvasLayer.index += 1

        self.changed = False
        self.source = None

    def setSource(self, source):
        self.source = source
        self.size = source.size()
        self.changed = True

    def synchronize(self, layer, updateThumbnail=False):
        if updateThumbnail and layer.changed:
            self._thumbnail = QImage(layer.getThumbnail())
            self.updated.emit()

        if not self.changed:
            return False

        layer.opacity = self._opacity
        layer.visible = self._visible
        layer.mode = self._mode
        if self.source:
            layer.source = QImage(self.source)
            self.source = None
        self.updated.emit()
        self.changed = False
        return True

    @pyqtProperty(str, notify=updated)
    def name(self):
        return self._name

    @name.setter
    def name(self, name):
        self._name = name
        self.changed = True

    @pyqtProperty(float, notify=updated)
    def opacity(self):
        return self._opacity

    @opacity.setter
    def opacity(self, opacity):
        self._opacity = opacity
        self.changed = True

    @pyqtProperty(bool, notify=updated)
    def visible(self):
        return self._visible

    @visible.setter
    def visible(self, visible):
        self._visible = visible
        self.changed = True

    @pyqtProperty(QImage, notify=updated)
    def thumbnail(self):
        return self._thumbnail
    

class CanvasSelectionShape():
    def __init__(self, tool, mode, bound):
        self.tool = tool
        self.mode = mode
        self.bound = bound
    
    def transform(self, offset, factor=1.0):
        shape = CanvasSelectionShape(self.tool, self.mode, [])
        if type(self.bound) == QRectF:
            a, b = self.bound.topLeft(), self.bound.bottomRight()
            shape.bound = QRectF(a*factor + offset,b*factor + offset)
        if type(self.bound) == list:
            shape.bound = [p*factor + offset for p in self.bound]
        return shape
    
    def center(self):
        return self.boundingRect().center()
    
    def boundingRect(self):
        if type(self.bound) == QRectF:
            return self.bound
        if type(self.bound) == list:
            return QPolygonF(self.bound).boundingRect()

class CanvasSelection(QObject):
    updated = pyqtSignal()
    def __init__(self, parent=None):
        super().__init__(parent)
        self._shapes = []
        self._offset = QPointF(0,0)
        self._visible = True
        self._mode = CanvasSelectionMode.NORMAL
        self._tool = CanvasTool.RECTANGLE_SELECT
        self._current = None
        self._mask = None

    def setOffset(self, offset):
        self._offset = offset
        self.updated.emit()
        
    def applyOffset(self):
        self._shapes = [shape.transform(self._offset) for shape in self._shapes]
        self._offset = QPointF(0,0)
        self.updated.emit()

    def setVisible(self, visible):
        self._visible = visible
        self.updated.emit()

    def setTool(self, tool):
        self._tool = tool
        self.updated.emit()

    def setMode(self, mode):
        self._mode = mode
        self.updated.emit()

    def setCurrent(self, current):
        if current:
            self._current = CanvasSelectionShape(self._tool, self._mode, current)
        else:
            self._current = None
        self.updated.emit()

    def addCurrent(self):
        if self._current:
            self._shapes.append(self._current)
            self._current = None
            self.updated.emit()

    def setMask(self, mask):
        self._mask = mask

    def clearMask(self):
        self._mask = None
        self.updated.emit()
    
    def clear(self):
        self._shapes = []
        self._current = None
        self._offset = QPointF(0,0)
        self._visible = True
        self._mode = CanvasSelectionMode.NORMAL
        self._tool = CanvasTool.RECTANGLE_SELECT
        self._mask = None
        self.updated.emit()

    def synchronize(self, other):
        self._shapes = other._shapes
        self._offset = other._offset
        self._current = other._current
        self._mask = other._mask

    def copy(self):
        selection = CanvasSelection()
        selection.synchronize(self)
        return selection

    def center(self):
        shapes = self.shapes
        if len(shapes) == 0:
            return None
        return sum([shape.center() for shape in shapes], QPointF())/len(shapes)
    
    def boundingRect(self):
        shapes = self.shapes
        if len(shapes) == 0:
            return None
        rect = None
        for shape in shapes:
            if not rect:
                rect = shape.boundingRect()
            else:
                rect = rect.united(shape.boundingRect())
        return rect

    @pyqtProperty(list, notify=updated)
    def shapes(self):
        if self._current:
            shapes = self._shapes + [self._current]
        else:
            shapes = self._shapes
        return [shape.transform(self._offset) for shape in shapes]
    
    @pyqtProperty(bool, notify=updated)
    def visible(self):
        return self._visible
    
    @pyqtProperty(QImage, notify=updated)
    def mask(self):
        if not self._mask:
            return QImage()
        else:
            self._mask.setOffset(self._offset.toPoint())
            return self._mask

class Canvas(QQuickFramebufferObject):
    sourceUpdated = pyqtSignal()
    layersUpdated = pyqtSignal()
    brushUpdated = pyqtSignal()
    toolUpdated = pyqtSignal()
    selectionUpdated = pyqtSignal()
    needsUpdated = pyqtSignal()
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setTextureFollowsItemSize(False)
        self.setMirrorVertically(True)

        self._source = ""
        self._sourceSize = QSize(0,0)
        self._tool = CanvasTool.BRUSH
        self._brush = CanvasBrush()
        self._layers = {} # key -> layer
        self._layersOrder = [] # index -> key
        self._activeLayer = -1
        self._floating = False

        self.changes = CanvasChanges()
        self.lastMousePosition = None

        self.thumbnailTimer = QTimer(self)
        self.thumbnailTimer.timeout.connect(self.updateThumbnails)
        self.thumbnailTimer.start(250)
        self.thumbnailsUpdate = False

        self._toolStart = None
        self._toolActive = False

        self._selection = CanvasSelection()
        self._selectPath = []

        self._moveOffset = QPointF()

        self._needsUpdate = False

    def getChanges(self):
        changes = self.changes
        changes.brush = self._brush
        changes.tool = self._tool
        changes.layer = self._activeLayer
        changes.move = self._moveOffset
        changes.selection = self._selection
        self.changes = CanvasChanges()
        return changes

    def synchronize(self, renderer):
        self.synchronizeRestore(renderer)
        self.synchronizeLayers(renderer)
        self.synchronizeSelection(renderer)    
        
        self._needsUpdate = False

    def synchronizeSelection(self, renderer):
        self._floating = renderer.floating
        if self._tool == CanvasTool.MOVE:
            self._selection.setOffset(renderer.floatingOffset + renderer.floatingPosition)
            self._selection.setVisible(self._moveOffset.manhattanLength() == 0)

    def synchronizeLayers(self, renderer):
        renderer.layersOrder = self._layersOrder
    
        for key in renderer.layersOrder:
            if not key in renderer.layers:
                renderer.layers[key] = renderer.createLayer(self._layers[key]._size)
                self.layersUpdated.emit()
            self._layers[key].synchronize(renderer.layers[key], self.thumbnailsUpdate)
        self.thumbnailsUpdate = self.changes.reset

    def synchronizeRestore(self, renderer):
        if renderer.restoredSelection != None:
            self._selection.synchronize(renderer.restoredSelection)
            renderer.restoredSelection = None
            if renderer.floating:
                self.tool = CanvasTool.MOVE
    
        if renderer.restoredActive != None:
            self._activeLayer = renderer.restoredActive
            renderer.restoredActive = None

        if renderer.restoredOrder != None:
            self._layersOrder = renderer.restoredOrder
            renderer.restoredOrder = None

    @pyqtProperty(bool, notify=needsUpdated)
    def needsUpdate(self):
        return self._needsUpdate
    
    def requestUpdate(self):
        self._needsUpdate = True
        self.needsUpdated.emit()

    @pyqtSlot()
    def updateThumbnails(self):
        self.thumbnailsUpdate = True

    def createRenderer(self):
        return CanvasRenderer(self._sourceSize)

    @pyqtProperty(list, notify=layersUpdated)
    def layers(self):
        return [self._layers[key] for key in self._layersOrder]

    @pyqtProperty(int, notify=layersUpdated)
    def activeLayer(self):
        return self._activeLayer

    @activeLayer.setter
    def activeLayer(self, layer):
        self._activeLayer = layer
        self.layersUpdated.emit()

    @pyqtProperty(str, notify=sourceUpdated)
    def source(self):
        return self._source

    @source.setter
    def source(self, path):
        self._source = path
        self.sourceUpdated.emit()

    @pyqtProperty(QSize, notify=sourceUpdated)
    def sourceSize(self):
        return self._sourceSize

    @pyqtSlot()
    def load(self):
        source = QImage(self._source)
        self._sourceSize = source.size()
        self.sourceUpdated.emit()

        self.addLayer()
        self.getLayer(0).setSource(source)
        self.layersUpdated.emit()

        self.changes = CanvasChanges()
        self.changes.operations.add(CanvasOperation.LOAD)
        self.changes.operations.add(CanvasOperation.SET_SELECTION)
        self.changes.reset = True

    def addLayer(self):
        layer = CanvasLayer(f"Layer {len(self._layersOrder)}", self._sourceSize, self)
        self._layers[layer.index] = layer
        before, after = self._layersOrder[:self._activeLayer+1], self._layersOrder[self._activeLayer+1:]
        self._layersOrder = before + [layer.index] + after
        self._activeLayer = self._activeLayer + 1
    
    def getLayer(self, position):
        return self._layers[self._layersOrder[position]]

    def transformMousePosition(self, pos):
        if not self._sourceSize.width():
            return pos
        factor =  self.width()/self._sourceSize.width()
        offset = QPointF(self.x(), self.y())
        return (pos - offset) / factor

    @pyqtSlot(QPointF, int)
    def mousePressed(self, position, modifiers):
        self.requestUpdate()
        position = self.transformMousePosition(position)
        self._toolStart = position
        self._toolActive = True

        if self._tool in {CanvasTool.BRUSH, CanvasTool.ERASE}:
            self.changes.strokes.append(position)
            self.lastMousePosition = position

        if self._tool in {CanvasTool.RECTANGLE_SELECT, CanvasTool.ELLIPSE_SELECT, CanvasTool.PATH_SELECT}:
            
            self._selectPath = [position]
            if modifiers & Qt.ShiftModifier:
                self._selection.setMode(CanvasSelectionMode.ADD)
            elif modifiers & Qt.ControlModifier:
                self._selection.setMode(CanvasSelectionMode.SUBTRACT)
            else:
                self._selection.clear()
            self._selection.setTool(self._tool)

        if self._tool in {CanvasTool.MOVE}:
            self.changes.operations.add(CanvasOperation.MOVE)
            self._moveOffset = QPointF(0,0)

    @pyqtSlot(QPointF, int)
    def mouseReleased(self, position, modifiers):
        self.requestUpdate()
        self._toolActive = False
        position = self.transformMousePosition(position)
        if self._tool in {CanvasTool.BRUSH, CanvasTool.ERASE}:
            self.changes.operations.add(CanvasOperation.STROKE)
        if self._tool in {CanvasTool.RECTANGLE_SELECT, CanvasTool.ELLIPSE_SELECT, CanvasTool.PATH_SELECT}:
            self._selection.addCurrent()
            self.changes.operations.add(CanvasOperation.SET_SELECTION)
        if self._tool in {CanvasTool.MOVE}:
            self._moveOffset = QPointF(0,0)
            self.changes.operations.add(CanvasOperation.SET_MOVE)
        return

    @pyqtSlot(QPointF, int)
    def mouseDragged(self, position, modifiers):
        self.requestUpdate()
        position = self.transformMousePosition(position)
        if self._tool in {CanvasTool.BRUSH, CanvasTool.ERASE}:
            if self.lastMousePosition == None:
                self.changes.strokes.append(position)
                self.lastMousePositions = position
            else:
                last = QPointF(self.lastMousePosition)
                s = self._brush.getAbsoluteSpacing()
                v = QPointF(position.x()-last.x(), position.y()-last.y())
                m = (v.x()*v.x() + v.y()*v.y())**0.5
                r = m/s
                if r < 1:
                    return
                
                for i in range(1, int(r)+1):
                    f = i*s/m
                    p = QPointF(last.x()+v.x()*f, last.y()+v.y()*f)
                    self.changes.strokes.append(p)
                self.lastMousePosition = QPointF(p)
            
            self.changes.operations.add(CanvasOperation.UPDATE_STROKE)
            
        if self._tool in {CanvasTool.RECTANGLE_SELECT, CanvasTool.ELLIPSE_SELECT}:
            x1, y1 = self._toolStart.x(), self._toolStart.y()
            x2, y2 = position.x(), position.y()
            p1 = QPointF(min(x1,x2), min(y1, y2))
            p2 = QPointF(max(x1,x2), max(y1, y2))

            self._selection.setCurrent(QRectF(p1, p2))

        if self._tool in {CanvasTool.PATH_SELECT}:
            last = self._selectPath[0]
            delta = position - self._selectPath[-1]
            dist = (delta.x() * delta.x() + delta.y() * delta.y())**0.5
            if dist < 1:
                return

            self._selectPath.append(position)
            self._selection.setCurrent(self._selectPath + [self._selectPath[0]])
        
        if self._tool in {CanvasTool.MOVE}:
            self._moveOffset = position - self._toolStart
            self.changes.operations.add(CanvasOperation.UPDATE_MOVE)

    @pyqtSlot()
    def undo(self):
        if self._toolActive:
            return
        self.requestUpdate()
        self.changes.operations.add(CanvasOperation.UNDO)

    @pyqtSlot()
    def copy(self):
        self.changes.operations.add(CanvasOperation.COPY)
    
    @pyqtSlot()
    def cut(self):
        self.changes.operations.add(CanvasOperation.CUT)

    @pyqtSlot()
    def paste(self):
        if self._toolActive or self._floating:
            return
        
        image = QGuiApplication.clipboard().image()
        if not image.isNull():
            self.requestUpdate()
            self.changes.operations.add(CanvasOperation.PASTE)
            self.changes.paste = image
            self.tool = CanvasTool.MOVE
            self._selection.setVisible(False)

    @pyqtProperty(CanvasBrush, notify=brushUpdated)
    def brush(self):
        return self._brush

    @pyqtProperty(int, notify=toolUpdated)
    def tool(self):
        return self._tool.value

    @tool.setter
    def tool(self, tool):
        if self._tool == tool:
            return
        
        if self._tool == CanvasTool.MOVE:
            self.changes.operations.add(CanvasOperation.ANCHOR)
                    
        self.requestUpdate()
        self._tool = CanvasTool(tool)
        self.toolUpdated.emit()

    @pyqtProperty(CanvasSelection, notify=selectionUpdated)
    def selection(self):
        return self._selection

def registerTypes():
    qmlRegisterType(Canvas, "gui", 1, 0, "AdvancedCanvas")
    qmlRegisterUncreatableType(CanvasBrush, "gui", 1, 0, "CanvasBrush", "Not a QML type")
    qmlRegisterUncreatableType(CanvasLayer, "gui", 1, 0, "CanvasLayer", "Not a QML type")
    qmlRegisterUncreatableType(CanvasSelection, "gui", 1, 0, "CanvasSelection", "Not a QML type")
//
// Copyright (c) 2011-2014 Simon Mika <simon@mika.se>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.

use ooc-math
use ooc-base
import math
import structs/ArrayList
import Image
import RasterBgra, RasterMonochrome, RasterBgr
import Color
import StbImage

RasterImage: abstract class extends Image {
	distanceRadius: Int { get { return 1; } }
	buffer: ByteBuffer { get set }
	pointer: UInt8* { get { buffer pointer } }
	length: Int { get { buffer size } }
	stride: UInt { get set }
	apply: abstract func ~bgr (action: Func (ColorBgr))
	apply: abstract func ~yuv (action: Func (ColorYuv))
	apply: abstract func ~monochrome (action: Func (ColorMonochrome))
	init: func ~fromRasterImage (original: RasterImage) {
		super(original)
		this buffer = original buffer copy()
	}
	init: func (buffer: ByteBuffer, size: IntSize2D, coordinateSystem: CoordinateSystem, crop: IntShell2D) {
		super(size, coordinateSystem, crop, false)
		this buffer = buffer
	}
	resizeTo: func (size: IntSize2D) -> Image {
		result : Image
//	TODO: Actually resize the image
		resized := this
		result = resized
		result
	}
	copy: func ~fromParams (size: IntSize2D, transform: FloatTransform2D) -> This {
		transform = (this transform asFloatTransform2D()) * transform * (this transform asFloatTransform2D()) inverse
		mappingTransform := FloatTransform2D createTranslation(this size width / 2, this size height / 2) * transform
		upperLeft := mappingTransform * FloatPoint2D new(-size width / 2, -size width / 2)
		upperRight := mappingTransform * FloatPoint2D new(size width / 2, -size width / 2)
		downLeft := mappingTransform * FloatPoint2D new(-size width / 2, size width / 2)
		downRight := mappingTransform * FloatPoint2D new(size width / 2, size width / 2)
		source := FloatBox2D bounds([upperLeft, upperRight, downLeft, downRight])
		mappingTransformInverse := mappingTransform inverse
		upperLeft = mappingTransformInverse * source leftTop
		upperRight = mappingTransformInverse * source rightTop
		downLeft = mappingTransformInverse * source leftBottom
		downRight = mappingTransformInverse * source rightBottom
		this copy(size asFloatSize2D(), source, FloatPoint2D new(), FloatPoint2D new(), FloatPoint2D new())
	}
	copy: func ~fromMoreParams (size: FloatSize2D, source: FloatBox2D, upperLeft, upperRight, lowerLeft: FloatPoint2D) -> This {
		result := RasterBgra new(size ceiling() asIntSize2D())
//		TODO: The stuff
		result
	}

	open: static func ~unknownType (filename: String) -> This {
		x, y, n: Int
		data := StbImage load(filename, x&, y&, n&, 0)
		buffer := ByteBuffer new(x * y * n)
		// FIXME: Find a better way to do this using Dispose() or something
		memcpy(buffer pointer, data, x * y * n)
		StbImage free(data)
		result: This
		match (n) {
			case 1 =>
				result = RasterMonochrome new(buffer, IntSize2D new (x, y))
			case 3 =>
				result = RasterBgr new(buffer, IntSize2D new (x, y))
			case 4 =>
				result = RasterBgra new(buffer, IntSize2D new (x, y))
			case =>
				raise("Unsupported number of channels in image")
		}
		result
	}
}

//
//  KTX.cpp
//  ktx/src/ktx
//
//  Created by Zach Pomerantz on 2/08/2017.
//  Copyright 2017 High Fidelity, Inc.
//
//  Distributed under the Apache License, Version 2.0.
//  See the accompanying file LICENSE or http://www.apache.org/licenses/LICENSE-2.0.html
//

#include "KTX.h"

#include <algorithm> //min max and more

using namespace ktx;

const Header::Identifier ktx::Header::IDENTIFIER {{
    0xAB, 0x4B, 0x54, 0x58, 0x20, 0x31, 0x31, 0xBB, 0x0D, 0x0A, 0x1A, 0x0A
}};

Header::Header() {
    memcpy(identifier, IDENTIFIER.data(), IDENTIFIER_LENGTH);
}

uint32_t Header::evalMaxDimension() const {
    return std::max(pixelWidth, std::max(pixelHeight, pixelDepth));
}

uint32_t Header::evalMaxLevel() const {
    return 1 + log2(evalMaxDimension());
}

uint32_t Header::evalPixelWidth(uint32_t level) const {
    return std::max(pixelWidth >> level, 1U);
}
uint32_t Header::evalPixelHeight(uint32_t level) const {
    return std::max(pixelHeight >> level, 1U);
}
uint32_t Header::evalPixelDepth(uint32_t level) const {
    return std::max(pixelDepth >> level, 1U);
}

size_t Header::evalPixelSize() const {
    return glTypeSize; // Really we should generate the size from the FOrmat etc
}

size_t Header::evalRowSize(uint32_t level) const {
    auto pixelWidth = evalPixelWidth(level);
    auto pixSize = evalPixelSize();
    auto netSize = pixelWidth * pixSize;
    auto packing = netSize % 4;
    return netSize + (packing ? 4 - packing : 0);
}
size_t Header::evalFaceSize(uint32_t level) const {
    auto pixelHeight = evalPixelHeight(level);
    auto pixelDepth = evalPixelDepth(level);
    auto rowSize = evalRowSize(level);
    return pixelDepth * pixelHeight * rowSize;
}
size_t Header::evalImageSize(uint32_t level) const {
    auto faceSize = evalFaceSize(level);
    if (numberOfFaces == 6 && numberOfArrayElements == 0) {
        return faceSize;
    } else {
        return (numberOfArrayElements * numberOfFaces * faceSize);
    }
}


KTX::KTX() {
}

void KTX::resetStorage(Storage* storage) {
    _storage.reset(storage);
}

const Header* KTX::getHeader() const {
    if (_storage) {
        return reinterpret_cast<const Header*> (_storage->_bytes);
    } else {
        return nullptr;
    }
}

const Byte* KTX::getKeyValueData() const {
    if (_storage) {
        return (_storage->_bytes + sizeof(Header));
    } else {
        return nullptr;
    }
}

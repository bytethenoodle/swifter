//
//  Socket+File.swift
//  Swifter
//
//  Copyright (c) 2014-2016 Damian Kołakowski. All rights reserved.
//

#if os(Linux)
import Glibc
#else
import Foundation
#endif


#if os(iOS) || os(tvOS) || os (Linux)

struct sf_hdtr { }

private func sendfileImpl(source: Int32, _ target: Int32, _: off_t, _: UnsafeMutablePointer<off_t>, _: UnsafeMutablePointer<sf_hdtr>?, _: Int32) -> Int32 {
    var buffer = [UInt8](repeating: 0, count: 1024)
    while true {
        let readResult = read(source, &buffer, buffer.count)
        guard readResult > 0 else {
            return Int32(readResult)
        }
        var writeCounter = 0
        while writeCounter < readResult {
            let writeResult = write(target, &buffer + writeCounter, readResult - writeCounter)
            guard writeResult > 0 else {
                return Int32(writeResult)
            }
            writeCounter = writeCounter + writeResult
        }
    }
}

#else

private let sendfileImpl = sendfile

#endif

extension Socket {
    
    public func writeFile(_ file: String.File) throws -> Void {
        var offset: off_t = 0
        var sf: sf_hdtr = sf_hdtr()
        
        #if os(iOS) || os(tvOS) || os (Linux)
        let result = sendfileImpl(source: fileno(file.pointer), self.socketFileDescriptor, 0, &offset, nil, 0)
        #else
        let result = sendfile(fileno(file.pointer), self.socketFileDescriptor, 0, &offset, &sf, 0)
        #endif
        
        if result == -1 {
            throw SocketError.writeFailed("sendfile: " + Process.lastErrno)
        }
    }
    
}

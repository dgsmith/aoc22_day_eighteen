import Darwin
import Foundation

let log = true

var xyHash = [Position2D: [Int]]()
var zyHash = [Position2D: [Int]]()
var xzHash = [Position2D: [Int]]()

let filePath = "/Users/grayson/code/advent_of_code/2022/day_eighteen/test.txt"
guard let filePointer = fopen(filePath, "r") else {
    preconditionFailure("Could not open file at \(filePath)")
}
var lineByteArrayPointer: UnsafeMutablePointer<CChar>?
defer {
    fclose(filePointer)
    lineByteArrayPointer?.deallocate()
}
var lineCap: Int = 0
while getline(&lineByteArrayPointer, &lineCap, filePointer) > 0 {
    let line = String(cString:lineByteArrayPointer!)
    
    let matches = line.matches(of: #/\d+/#)
    guard matches.count == 3 else {
        fatalError()
    }
    
    let position = Position3D(x: Int(matches[0].output)!,
                              y: Int(matches[1].output)!,
                              z: Int(matches[2].output)!)
    
    let xy = Position2D(x: position.x, y: position.y)
    let zy = Position2D(x: position.z, y: position.y)
    let xz = Position2D(x: position.x, y: position.z)
    
    if xyHash[xy] == nil {
        xyHash[xy] = [position.z]
    } else {
        xyHash[xy]!.append(position.z)
    }
    
    if zyHash[zy] == nil {
        zyHash[zy] = [position.x]
    } else {
        zyHash[zy]!.append(position.x)
    }
    
    if xzHash[xz] == nil {
        xzHash[xz] = [position.y]
    } else {
        xzHash[xz]!.append(position.y)
    }
}

struct Position2D: Hashable {
    let x: Int
    let y: Int
}

struct Position3D: Hashable {
    let x: Int
    let y: Int
    let z: Int
}

func countSides(in plane: [Position2D: [Int]]) -> Int {
    var sideCount = 0
    for elem in plane {
        var lastValue: Int?
        for index in elem.value.sorted() {
            print("proc \(index)")
            if lastValue == nil {
                print("  first")
                sideCount += 1 // first facing side
                lastValue = index
                continue
            }
            
            if (lastValue! - index).magnitude > 1 {
                print("  jump=\((lastValue! - index).magnitude)")
                sideCount += 2 // tail of side, front of next side
            }
            lastValue = index
        }
        sideCount += 1 // tail of side
        print("calculated=\(sideCount) for \(elem.value.sorted())")
    }
    return sideCount
}

print("xy=\(countSides(in: xyHash)) zy=\(countSides(in: zyHash)) xz=\(countSides(in: xzHash))")
print(countSides(in: xyHash) + countSides(in: zyHash) + countSides(in: xzHash))

//for elem in xyHash {
//    print("(\(elem.key.x), \(elem.key.y)): \(elem.value.sorted())")
//}
//print()
//
//for elem in zyHash {
//    print("(\(elem.key.x), \(elem.key.y)): \(elem.value.sorted())")
//}
//print()
//
//for elem in xzHash {
//    print("(\(elem.key.x), \(elem.key.y)): \(elem.value.sorted())")
//}

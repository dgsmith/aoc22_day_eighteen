import Darwin
import Foundation

let log = false

var inputPositions = [Position3D]()

let filePath = "/Users/grayson/code/advent_of_code/2022/day_eighteen/input.txt"
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
    
    inputPositions.append(position)
}

func hashes(from positions: [Position3D]) -> (xy: [Position2D: [Int]], zy: [Position2D: [Int]], xz: [Position2D: [Int]]) {
    var localXy = [Position2D: [Int]]()
    var localZy = [Position2D: [Int]]()
    var localXz = [Position2D: [Int]]()
    
    for position in positions {
        let xy = Position2D(x: position.x, y: position.y)
        let zy = Position2D(x: position.z, y: position.y)
        let xz = Position2D(x: position.x, y: position.z)
        
        if localXy[xy] == nil {
            localXy[xy] = [position.z]
        } else {
            localXy[xy]!.append(position.z)
        }
        
        if localZy[zy] == nil {
            localZy[zy] = [position.x]
        } else {
            localZy[zy]!.append(position.x)
        }
        
        if localXz[xz] == nil {
            localXz[xz] = [position.y]
        } else {
            localXz[xz]!.append(position.y)
        }
    }
    
    return (xy: localXy, zy: localZy, xz: localXz)
}

struct Position2D: Hashable, CustomStringConvertible {
    let x: Int
    let y: Int
    
    var description: String {
        return "(\(x), \(y))"
    }
}

struct Position3D: Hashable, CustomStringConvertible {
    let x: Int
    let y: Int
    let z: Int
    
    var description: String {
        return "(\(x), \(y), \(z))"
    }
    
    var xy: Position2D {
        return Position2D(x: x, y: y)
    }
    
    var zy: Position2D {
        return Position2D(x: z, y: y)
    }
    
    var xz: Position2D {
        return Position2D(x: x, y: z)
    }
}

enum PlaneType {
    case xy
    case zy
    case xz
}

func convert(hash: [Position2D: [Int]], of type: PlaneType) -> [Position3D] {
    var points = [Position3D]()
    
    for elem in hash {
        for index in elem.value {
            let point: Position3D
            switch type {
            case .xy:
                point = Position3D(x: elem.key.x, y: elem.key.y, z: index)
            case .zy:
                point = Position3D(x: index, y: elem.key.y, z: elem.key.x)
            case .xz:
                point = Position3D(x: elem.key.x, y: index, z: elem.key.y)
            }
            points.append(point)
        }
    }
    
    return points
}

func convert(points: [Position3D], of type: PlaneType) -> [Position2D: [Int]] {
    var hash = [Position2D: [Int]]()
    
    for point in points {
        let key: Position2D
        let value: Int
        switch type {
        case .xy:
            key = Position2D(x: point.x, y: point.y)
            value = point.z
        case .zy:
            key = Position2D(x: point.z, y: point.y)
            value = point.x
        case .xz:
            key = Position2D(x: point.x, y: point.z)
            value = point.y
        }
        
        if hash[key] == nil {
            hash[key] = [value]
        } else {
            hash[key]!.append(value)
        }
    }
    
    return hash
}

func countSides(in plane: [Position2D: [Int]]) -> (allSides: Int, jumps: [Position2D: [Int]]) {
    var sideCount = 0
    var jumps = [Position2D: [Int]]()
    
    for elem in plane {
        if log {
            print("key: \(elem.key)")
        }
        var lastValue: Int?
        for index in elem.value.sorted() {
            if log {
                print("  processing \(index)")
            }
            if lastValue == nil {
                if log {
                    print("    first")
                }
                sideCount += 1 // first facing side
                lastValue = index
                continue
            }
            
            if (lastValue! - index).magnitude > 1 {
                if log {
                    print("    jump size=\((lastValue! - index).magnitude - 1)")
                }
                
                sideCount += 2 // tail of side, front of next side
                
                // Add to jump indices
                let min = min(lastValue!, index) + 1
                let max = max(lastValue!, index)
                for jumpIndex in min..<max {
                    if log {
                        print("    adding jump=\(elem.key), \(jumpIndex)")
                    }
                    if jumps[elem.key] == nil {
                        jumps[elem.key] = [jumpIndex]
                    } else {
                        jumps[elem.key]!.append(jumpIndex)
                    }
                }
            }
            
            lastValue = index
        }
        sideCount += 1 // tail of side
        if log {
            print("calculated=\(sideCount) for \(elem.value.sorted())")
        }
    }
    
    return (allSides: sideCount, jumps: jumps)
}

let inputHashes = hashes(from: inputPositions)


let xy = countSides(in: inputHashes.xy)
let xyJumps = Set(convert(hash: xy.jumps, of: .xy))
var jumps = xyJumps
print(jumps.count)

let zy = countSides(in: inputHashes.zy)
let zyJumps = Set(convert(hash: zy.jumps, of: .zy))
var removedJumps = jumps.symmetricDifference(zyJumps)
jumps = jumps.intersection(zyJumps)
print(removedJumps.count)
print(jumps.count)

let xz = countSides(in: inputHashes.xz)
let xzJumps = Set(convert(hash: xz.jumps, of: .xz))
removedJumps.formUnion(jumps.symmetricDifference(xzJumps))
jumps = jumps.intersection(xzJumps)
print(removedJumps.count)
print(jumps.count)

let total = xy.allSides + zy.allSides + xz.allSides
print("xy=\(xy.allSides) zy=\(zy.allSides) xz=\(xz.allSides), total: \(total)")



for removedJump in removedJumps {
    var index = 1
    while true {
        let jumpToCheck = Position3D(x: removedJump.x, y: removedJump.y, z: removedJump.z + index)
        if jumps.remove(jumpToCheck) == nil {
            break
        }
        
        if log {
            print("  removed \(jumpToCheck)")
        }
        
        index += 1
    }
    
    index = 1
    while true {
        let jumpToCheck = Position3D(x: removedJump.x, y: removedJump.y, z: removedJump.z - index)
        if jumps.remove(jumpToCheck) == nil {
            break
        }
        
        if log {
            print("  removed \(jumpToCheck)")
        }
        
        index += 1
    }
    
    index = 1
    while true {
        let jumpToCheck = Position3D(x: removedJump.x, y: removedJump.y + index, z: removedJump.z)
        if jumps.remove(jumpToCheck) == nil {
            break
        }
        
        if log {
            print("  removed \(jumpToCheck)")
        }
        
        index += 1
    }
    
    index = 1
    while true {
        let jumpToCheck = Position3D(x: removedJump.x, y: removedJump.y - index, z: removedJump.z)
        if jumps.remove(jumpToCheck) == nil {
            break
        }
        
        if log {
            print("  removed \(jumpToCheck)")
        }
        
        index += 1
    }
    
    index = 1
    while true {
        let jumpToCheck = Position3D(x: removedJump.x + index, y: removedJump.y, z: removedJump.z)
        if jumps.remove(jumpToCheck) == nil {
            break
        }
        
        if log {
            print("  removed \(jumpToCheck)")
        }
        
        index += 1
    }
    
    index = 1
    while true {
        let jumpToCheck = Position3D(x: removedJump.x - index, y: removedJump.y, z: removedJump.z)
        if jumps.remove(jumpToCheck) == nil {
            break
        }
        
        if log {
            print("  removed \(jumpToCheck)")
        }
        
        index += 1
    }
}

let innerHashes = hashes(from: Array(jumps))
let innerXy = countSides(in: innerHashes.xy)
let innerZy = countSides(in: innerHashes.zy)
let innerXz = countSides(in: innerHashes.xz)

let innerTotal = innerXy.allSides + innerZy.allSides + innerXz.allSides
print("INNER xy=\(innerXy.allSides) zy=\(innerZy.allSides) xz=\(innerXz.allSides), total: \(innerTotal)")

print("subtracted: \(total - innerTotal)")

print()
//for inputPosition in inputPositions {
//    print("\(inputPosition.x),\(inputPosition.y),\(inputPosition.z)")
//}
for jump in jumps {
    print("\(jump.x),\(jump.y),\(jump.z)")
}


// if any jump is removed, all "connected jumps must also be removed!!!!!

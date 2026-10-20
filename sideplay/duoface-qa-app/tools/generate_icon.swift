import Foundation
import AppKit
let sizes:[Int]=[80,120,152,180]
let output=CommandLine.arguments.count>1 ? CommandLine.arguments[1] : "."
for size in sizes {
 let image=NSImage(size:NSSize(width:size,height:size))
 image.lockFocus()
 let rect=NSRect(x:0,y:0,width:size,height:size)
 NSColor(calibratedRed:0.06,green:0.15,blue:0.33,alpha:1).setFill()
 NSBezierPath(roundedRect:rect,xRadius:Double(size)*0.22,yRadius:Double(size)*0.22).fill()
 let pad=CGFloat(size)*0.115
 NSColor(calibratedRed:0.29,green:0.72,blue:0.99,alpha:1).setStroke()
 let border=NSBezierPath(roundedRect:rect.insetBy(dx:pad,dy:pad),
                          xRadius:Double(size)*0.12,yRadius:Double(size)*0.12)
 border.lineWidth=CGFloat(size)*0.03;border.stroke()
 let title="DF"
 let font=NSFont.systemFont(ofSize:CGFloat(size)*0.37,weight:.bold)
 let attrs:[NSAttributedString.Key:Any]=[.font:font,.foregroundColor:NSColor.white]
 let str=NSAttributedString(string:title,attributes:attrs)
 let sz=str.size()
 str.draw(at:NSPoint(x:(CGFloat(size)-sz.width)/2,
                     y:(CGFloat(size)-sz.height)/2))
 image.unlockFocus()
 guard let tiff=image.tiffRepresentation,
       let rep=NSBitmapImageRep(data:tiff),
       let png=rep.representation(using:.png,properties:[:]) else {
   fatalError("Icon rendering failed")
 }
 let name:[Int:String]=[80:"AppIcon40x40@2x.png",
                       120:"AppIcon60x60@2x.png",
                       152:"AppIcon76x76@2x.png",
                       180:"AppIcon60x60@3x.png"]
 try png.write(to:URL(fileURLWithPath:output).appendingPathComponent(name[size]!))
 print("App icon \(size)x\(size) rendered")
}

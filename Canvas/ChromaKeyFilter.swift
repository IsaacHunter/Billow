//
// Copyright 2014 Scott Logic
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
import CoreImage

class ChromaKeyFilter: CIFilter {
  // MARK: - Properties
  var kernel: CIColorKernel?
  var inputImage: CIImage?
  var activeColor = CIColor(red: 0.549019608, green: 0.211764706, blue: 0.909803922, alpha: 1)
  var threshold: CGFloat = 0.8
    
  // MARK: - Initialization
  override init() {
    super.init()
    kernel = createKernel()
  }
  
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)!
    kernel = createKernel()
  }
  
  // MARK: - API
  override var outputImage : CIImage! {
    if let inputImage = inputImage,
       let kernel = kernel {
        let dod = inputImage.extent
        let args = [inputImage as AnyObject, activeColor as AnyObject, threshold as AnyObject]
        return kernel.apply(extent: dod, arguments: args)
    }
    return nil
  }
  
  // MARK: - Utility methods
  private func createKernel() -> CIColorKernel {
    let kernelString =
    "kernel vec4 chromaKey( __sample s, __color c, float threshold ) { \n" +
    "  vec4 diff = s.rgba - c;\n" +
    "  float distance = length( diff );\n" +
    "  s.a = compare( distance - threshold, 0.0, s.a );\n" +
    "  return vec4( s.rgba ); \n" +
    "}"
    return CIColorKernel(source: kernelString)!
  }
}

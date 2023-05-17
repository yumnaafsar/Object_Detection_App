import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tflite/tflite.dart';
import 'main.dart';

class MyHome extends StatefulWidget {
  const MyHome({ Key? key }) : super(key: key);

  @override
  State<MyHome> createState() => _MyHomeState();
}

class _MyHomeState extends State<MyHome> {

  CameraController? cameraController;
  CameraImage? cameraImage;
  bool isWorking=false;
  double? imageHeight;
  double? imageWidth;
  List? recognitionlList;

  void initCamera(){
    cameraController = CameraController(cameras![0], ResolutionPreset.medium);
    cameraController!.initialize().then((value) => {

      setState(() {
        cameraController!.startImageStream((imageFromStream) {
          if(!isWorking){
            isWorking=true;
            cameraImage=imageFromStream;
            runModel();
          }
        });
      },)

    });

  }

  Future loadModel()async{
    Tflite.close();

    try {
      String? response= await Tflite.loadModel(
        model: "assets/ssd_mobilenet.tflite",
        labels: "assets/ssd_mobilenet.txt",
        );
      print("Response: "+ response.toString());
    } catch (e) {
      print("Exception: "+ e.toString());
    }
  }

  void runModel() async{
    imageHeight=cameraImage!.height + 0.0;
    imageWidth= cameraImage!.width + 0.0;

    recognitionlList= await Tflite.detectObjectOnFrame(
      bytesList: cameraImage!.planes.map((plane){
        return plane.bytes;
      }).toList(),
      imageHeight: cameraImage!.height,
      imageWidth: cameraImage!.width,
      threshold: 0.5,
    );

    isWorking =false;
    setState(() {
      cameraImage;
    });
  }

  List<Widget> displayBoxesAroundDetectedObjects(Size screen){
    if(recognitionlList == null){
      return [];
    }

    if(imageHeight == null || imageWidth == null){
      return [];
    }

    double? factorX = screen.width;
    double? factorY = screen.height;

    return recognitionlList!.map((result) {
      return Positioned(
        left: result["rect"]['x'] * factorX,
        right: result["rect"]['y'] * factorY,
        width: result["rect"]['w'] * factorX,
        height: result["rect"]['h'] * factorY,
        child: Container(
          decoration: BoxDecoration(
            borderRadius:BorderRadius.all(
              Radius.circular(10.0),
            ),
            border: Border.all(
                color:Colors.green,
                width:2.0,
              ) 
          ),
          child: Text("${result['detectClass']} ${(result['confidenceInClass']*100).toStringAsFixed(0)}%",
          style: TextStyle(color: Colors.green, fontSize: 16.0
          ),
          ),
        )
      );
    }).toList();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    cameraController!.stopImageStream();
    Tflite.close();
  }

  @override
  void initState(){
    super.initState();
    initCamera();
    loadModel();
  }

  Widget build(BuildContext context) {

    List<Widget> stackChildrenWidgets=[];
    Size size=MediaQuery.of(context).size;

    stackChildrenWidgets.add(
      Positioned(
        height: size.height,
        width: size.width,
        child: Container(
           height: size.height,
           child: (!cameraController!.value.isInitialized)? Container():AspectRatio(
             aspectRatio:cameraController!.value.aspectRatio,
             child: CameraPreview(cameraController!),
             ),
      ))
    );

    if(cameraImage != null)
    {
      stackChildrenWidgets.addAll(displayBoxesAroundDetectedObjects(size));
    }

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Container(
        color: Colors.black,
        child: Stack(
          children:stackChildrenWidgets,
        ),
      )),
    );
  }
}
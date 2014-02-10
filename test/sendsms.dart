//import 'package:unittest/unittest.dart';
import 'package:smsservices/smsservices.dart';

void main(){
  var s = new smsru("1a053506-d720-6c74-7578-abcf546924f3");
  var res = s.send({"+79216527978":"test2"}).then(
      (v){
        print(v); 
      }
  );
}



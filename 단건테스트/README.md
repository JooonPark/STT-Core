## 사용방법

+ ./test.sh <서비스코드> <응답코드> <테스트음성파일 절대경로> <콜백URL>
  ```
  ex)$ ./test.sh 2 0 /home/gosh2/smp/c-agent/test/svc/2/wav/hi.wav http://172.27.0.78:9090/stt/test
     응답코드가 0 일 경우 callback 유형
  ```

  ```
  ex) ./test.sh 2 1 /home/gosh2/smp/c-agent/test/svc/2/wav/hi.wav
     응답코드가 1일 경우 Response 유형으로 Callbackurl 미필요
  ``` 


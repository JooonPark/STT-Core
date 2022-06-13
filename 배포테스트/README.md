## 사용방법

+ ./deploy.sh <배포할 모델파일 절대경로> <서비스코드> <배포유형>
  ```
  ex)$ ./deploy.sh /home/gosh2/smp/r-agent/deploy/model/svc/2/model_2.tar.gz 21 CLASS
     배포유형이 CLASS 일 경우 CLASS LM 배포
  ```

  ```
  ex)$ ./deploy.sh /home/gosh2/smp/r-agent/deploy/model/svc/2/model_2.tar.gz 21 SERVICE
     배포유형이 SERVICE 일 경우 SERVICE LM 배포 (현재 미지원)
  ``` 


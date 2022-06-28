## 사용방법

+ ./train.sh <콜백URL> <학습데이터 파일 절대경로> <서비스코드> <학습유형>
  ```
  ex)$ ./train.sh http://172.27.0.78:9090/stt/train/callback /nas/trainData 2 CLASS
     학습유형이 CLASS 일 경우 CLASS LM 학습
  ```

  ```
  ex)$ ./train.sh http://172.27.0.78:9090/stt/train/callback /nas/trainData 2 SERVICE
     학습유형이 SERVICE 일 경우 SERVICE LM 학습 (현재 미지원)
  ``` 


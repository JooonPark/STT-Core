# 단건 테스트용 클라이언트

> 결과파일 경로 : main/result/stt_client

## 업데이트 사항
1. 해시값 삭제 후 서비스코드로 바로 stt client 요청 가능
2. voicekit 라이브러리를 바이너리에 링킹하여 voicekit library 참조할 필요 없음

## 사용 방법 예

```
./stt_client -i <ip> -p <port> -f <파일경로> -s <서비스코드> -k <콜키>
./stt_client -i 127.0.0.1 -p 11234 -f ../sound/0_0.pcm -s 2 -k 19900625
```


stt 결과는 <파일경로>.stt 파일로 저장

 ex) 입력 : ../sound/0_0.pcm >> 출력 ../sound/0_0.pcm.stt

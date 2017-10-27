# AzCopy reference

## Azure Storage to Local VM.

```shell
AzCopy /Source:https://********.blob.core.windows.net/******* /Dest:"G:\****\***\Backup" /SourceKey:************************************************************* /Pattern:"*****************************************"
```

---

## Local VM to Azure Storage

```shell
AzCopy /Source:"G:\******\********\********\Backup" /Dest:https://**********.blob.core.windows.net/******** /DestKey:**********************************************************
```

---

## One storage to another storage.

```shell
AzCopy /Source:https://*******.blob.core.windows.net/vhds /Dest:https://******.blob.core.windows.net/***** /sourcekey:************************************************************ /destkey:*********************************************** /Pattern:"***********.vhd"
```






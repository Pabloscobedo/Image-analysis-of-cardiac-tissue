#Requires AutoHotkey v2.0
#SingleInstance Force
SendMode "Input"
SetTitleMatchMode 2

vdTitle := "VirtualDub2"
outSuffix := "_AVI"

inDir := DirSelect("Selecciona la carpeta con los MP4")
if !inDir
    ExitApp

outDir := inDir "\AVI"
DirCreate(outDir)

if !WinExist(vdTitle) {
    MsgBox "Abre VirtualDub2 y vuelve a ejecutar el script."
    ExitApp
}

files := []
Loop Files, inDir "\*.mp4"
    files.Push(A_LoopFileFullPath)

if files.Length = 0 {
    MsgBox "No se encontraron MP4."
    ExitApp
}

MsgBox "Se convertirán " files.Length " videos.`n" 
     . "IMPORTANTE: Antes, en VirtualDub2 deja configurado:`n"
     . "Video → Compression… → Uncompressed RGB/YCbCr.`n"
     . "NO uses teclado ni ratón mientras corre."

for f in files {

    WinActivate vdTitle
    if !WinWaitActive(vdTitle, , 3) {
        MsgBox "No pude activar VirtualDub2."
        ExitApp
    }

    ; ---------- ABRIR (reintentos) ----------
    if !OpenVideoFile(f) {
        MsgBox "No pude abrir este archivo, se salta:`n" f
        continue
    }

    ; Espera extra para que cargue
    Sleep 1500

    ; ---------- GUARDAR ----------
    outFile := outDir "\" FileNameNoExt(f) outSuffix ".avi"
    if !SaveAVI(outFile) {
        MsgBox "No pude guardar este archivo, se salta:`n" f
        continue
    }

    ; Esperar a que VirtualDub2 termine realmente antes de pasar al siguiente
    WaitUntilReady()
}

MsgBox "CONVERSIÓN TERMINADA.`nSalida: " outDir
ExitApp


; ------------------ Funciones ------------------

OpenVideoFile(path) {
    global vdTitle
    Loop 3 {
        WinActivate vdTitle
        Sleep 200
        Send "^o"

        ; en tu captura dice "Open video file"
        if WinWaitActive("Open video", , 3) {
            Sleep 300
            A_Clipboard := path
            Sleep 150
            Send "^v"
            Sleep 150
            Send "{Enter}"

            ; Si aparece RAW, cancelar
            if WinWaitActive("Import Options", , 1) {
                Send "{Esc}"
                return false
            }
            return true
        }

        ; limpiar modales y reintentar
        Send "{Esc}"
        Sleep 300
    }
    return false
}

SaveAVI(outPath) {
    global vdTitle
    Loop 3 {
        WinActivate vdTitle
        Sleep 200
        Send "{F7}"

        if WinWaitActive("Save", , 3) || WinWaitActive("Guardar", , 3) {
            Sleep 300
            A_Clipboard := outPath
            Sleep 150
            Send "^v"
            Sleep 150
            Send "{Enter}"

            ; sobrescritura
            if WinWaitActive("Confirm Save As", , 1)
                Send "{Enter}"

            return true
        }

        Send "{Esc}"
        Sleep 300
    }
    return false
}

WaitUntilReady() {
    global vdTitle
    ; Estrategia: cada 1s intentamos abrir el diálogo Open;
    ; si aparece, significa que VirtualDub2 ya no está ocupado.
    Loop 600 { ; hasta 10 minutos máximo
        WinActivate vdTitle
        Sleep 150
        Send "^o"
        if WinWaitActive("Open video", , 1) {
            Send "{Esc}"
            Sleep 300
            return
        }
        Sleep 1000
    }
    ; Si tarda demasiado, igual seguimos (pero avisamos)
    MsgBox "Aviso: tardó demasiado en terminar de guardar. Continuaré."
}

FileNameNoExt(path) {
    SplitPath path, &name, , , &nameNoExt
    return nameNoExt
}
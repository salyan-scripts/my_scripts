# Define os arquivos de entrada
$arquivos = Get-ChildItem -Include *.mkv, *.mp4 -Recurse

foreach ($arquivo in $arquivos) {
    $nomeOriginal = $arquivo.Name
    $apenasNome = $arquivo.BaseName
    $ext = $arquivo.Extension

    # 1. Remove colchetes primeiro
    $processado = $apenasNome -replace '\[[^\]]*\]', ''

    # 2. Lógica de captura:
    # Captura o texto ANTES do padrão SxxExx (case insensitive)
    # E o próprio padrão SxxExx. O resto é descartado.
    if ($processado -match '^(.*?)(S\d{2}E\d{2})') {
        # $matches[1] é o nome da série, $matches[2] é o SxxExx
        $novoNomeBase = ($matches[1] + $matches[2])
        
        # 3. Substitui espaços e sublinhados por pontos
        # 4. Remove pontos duplicados
        # 5. Remove pontos no início e no fim
        $novoNomeBase = $novoNomeBase -replace '[ _]', '.' `
                                      -replace '\.+', '.' `
                                      -replace '^\.|\.$', ''

        $novoNome = "$novoNomeBase$ext"

        # Renomeia se o nome for diferente
        if ($nomeOriginal -ne $novoNome) {
            if (Test-Path $novoNome) {
                Write-Host "AVISO: '$novoNome' já existe. Pulando." -ForegroundColor Yellow
            } else {
                Write-Host "Renomeando: '$nomeOriginal' -> '$novoNome'"
                Rename-Item -Path $arquivo.FullName -NewName $novoNome
            }
        }
    } else {
        Write-Host "Ignorado (padrão SxxExx não encontrado): '$nomeOriginal'" -ForegroundColor Gray
    }
}
Write-Host "Concluído!" -ForegroundColor Green

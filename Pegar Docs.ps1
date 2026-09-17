# --- IN�CIO DA CONFIGURA��O ---

# 1. Caminho da pasta onde est�o as pastas "proposta_cpf"
$caminhoOrigem = "COLOQUE O CAMINHO DE ORIGEM"

# 2. Caminho da pasta RAIZ para onde os arquivos ser�o copiados.
#    O script criar� subpastas para cada tipo de arquivo (RECEITA, AVERB, etc.) dentro deste caminho.
$caminhoDestinoRaiz = "COLOQUE O CAMINHO PARA ONDE OS DOCUMENTOS VÃO"

# --- FIM DA CONFIGURA��O ---


#region --- C�DIGO DA JANELA GR�FICA (VISUAL MELHORADO) ---
function Get-UserInput {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Entrada de Propostas e Sele��o de Arquivos'
    $form.Size = New-Object System.Drawing.Size(400, 500)
    $form.StartPosition = 'CenterScreen'
    $form.TopMost = $true
    $form.FormBorderStyle = 'FixedDialog'
    $form.MaximizeBox = $false

    # R�tulo para as propostas
    $labelPropostas = New-Object System.Windows.Forms.Label
    $labelPropostas.Location = New-Object System.Drawing.Point(10, 10)
    $labelPropostas.Size = New-Object System.Drawing.Size(360, 20)
    $labelPropostas.Text = 'Cole as propostas abaixo (uma por linha):'
    $form.Controls.Add($labelPropostas)

    # Caixa de texto para as propostas
    $textBoxPropostas = New-Object System.Windows.Forms.TextBox
    $textBoxPropostas.Location = New-Object System.Drawing.Point(10, 40)
    $textBoxPropostas.Size = New-Object System.Drawing.Size(360, 180)
    $textBoxPropostas.Multiline = $true
    $textBoxPropostas.ScrollBars = 'Vertical'
    $textBoxPropostas.AcceptsReturn = $true
    $form.Controls.Add($textBoxPropostas)

    # Agrupador para as checkboxes
    $groupBox = New-Object System.Windows.Forms.GroupBox
    $groupBox.Location = New-Object System.Drawing.Point(10, 230)
    $groupBox.Size = New-Object System.Drawing.Size(360, 180)
    $groupBox.Text = "Selecione os tipos de arquivo para copiar"
    $form.Controls.Add($groupBox)
    
    # Checkboxes
    $tiposDeArquivo = @("AVERB", "CCB", "HOL", "ANTIFRAUDE", "COMP", "RG", "RECEITA")
    $checkboxes = @{}
    $posicaoY = 25
    $posicaoX = 20
    $coluna = 1
    foreach ($tipo in $tiposDeArquivo) {
        $checkbox = New-Object System.Windows.Forms.CheckBox
        $checkbox.Location = New-Object System.Drawing.Point($posicaoX, $posicaoY)
        $checkbox.Size = New-Object System.Drawing.Size(150, 20)
        $checkbox.Text = $tipo
        $groupBox.Controls.Add($checkbox) # Adiciona ao GroupBox
        $checkboxes[$tipo] = $checkbox
        
        $posicaoY += 30
        if ($coluna -eq 4) { # Cria uma segunda coluna
            $posicaoY = 25
            $posicaoX = 190
        }
        $coluna++
    }
    
    # --- IN�CIO DA ADI��O DOS CR�DITOS ---
    $creditosLabel = New-Object System.Windows.Forms.Label
    $creditosLabel.Location = New-Object System.Drawing.Point(10, 430)
    $creditosLabel.Size = New-Object System.Drawing.Size(200, 20)
    $creditosLabel.Text = 'Projetado por Pablo Orlando'
    $creditosLabel.ForeColor = [System.Drawing.Color]::DimGray
    $creditosLabel.Font = New-Object System.Drawing.Font($form.Font, [System.Drawing.FontStyle]::Italic)
    $form.Controls.Add($creditosLabel)
    # --- FIM DA ADI��O DOS CR�DITOS ---

    # Bot�es OK e Cancelar
    $okButton = New-Object System.Windows.Forms.Button; $okButton.Location = New-Object System.Drawing.Point(210, 425); $okButton.Size = New-Object System.Drawing.Size(75, 23); $okButton.Text = 'OK'; $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK; $form.AcceptButton = $okButton; $form.Controls.Add($okButton)
    $cancelButton = New-Object System.Windows.Forms.Button; $cancelButton.Location = New-Object System.Drawing.Point(290, 425); $cancelButton.Size = New-Object System.Drawing.Size(75, 23); $cancelButton.Text = 'Cancelar'; $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel; $form.CancelButton = $cancelButton; $form.Controls.Add($cancelButton)

    $form.Add_Shown({$textBoxPropostas.Select()})
    $result = $form.ShowDialog()

    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        return [PSCustomObject]@{ Propostas = $textBoxPropostas.Lines; TiposSelecionados = ($checkboxes.Keys | Where-Object { $checkboxes[$_].Checked }) }
    } else {
        return $null
    }
}
#endregion

# --- L�GICA PRINCIPAL DO SCRIPT ---

$userInput = Get-UserInput

if ($null -eq $userInput) { Write-Host "Processo cancelado pelo usu�rio."; return }

$propostasDesejadas = $userInput.Propostas | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { $_.Trim() }
$tiposSelecionados = $userInput.TiposSelecionados

if ($propostasDesejadas.Count -eq 0) { Write-Host "Nenhuma proposta foi inserida. Encerrando o script."; Read-Host -Prompt "Pressione Enter para sair"; return }
if ($tiposSelecionados.Count -eq 0) { Write-Host "Nenhum tipo de arquivo foi selecionado. Encerrando o script."; Read-Host -Prompt "Pressione Enter para sair"; return }

foreach ($tipo in $tiposSelecionados) {
    $caminhoDestinoEspecifico = Join-Path -Path $caminhoDestinoRaiz -ChildPath $tipo
    if (-not (Test-Path -Path $caminhoDestinoEspecifico -PathType Container)) {
        Write-Host "Criando pasta de destino: '$caminhoDestinoEspecifico'" -ForegroundColor DarkGray
        New-Item -Path $caminhoDestinoEspecifico -ItemType Directory -Force | Out-Null
    }
}

Write-Host "----------------------------------------------------" -ForegroundColor Green
Write-Host "Iniciando verifica��o para $($propostasDesejadas.Count) propostas..." -ForegroundColor Green
Write-Host "Arquivos a serem copiados: $($tiposSelecionados -join ', ')" -ForegroundColor Green
Write-Host "----------------------------------------------------"


foreach ($propostaDesejada in $propostasDesejadas) {
    
    $termoBusca = $propostaDesejada
    if ($propostaDesejada.Length -lt 9) {
        $termoBusca = "00" + $propostaDesejada
        Write-Host "INFO: Proposta '$propostaDesejada' tem < 9 d�gitos. Buscando como '$termoBusca'..." -ForegroundColor Magenta
    }

    $pasta = Get-ChildItem -Path $caminhoOrigem -Directory -Filter "${termoBusca}*" | Select-Object -First 1

    if ($null -eq $pasta) {
        Write-Host "($propostaDesejada) -> AVISO: Sem pasta." -ForegroundColor Gray
        continue
    }
    
    Write-Host "Processando pasta encontrada: $($pasta.Name)"
    
    foreach ($tipoArquivo in $tiposSelecionados) {
        
        $arquivoEncontrado = Get-ChildItem -Path $pasta.FullName -Recurse -File | Where-Object { $_.Name -like "*$tipoArquivo*" } | Select-Object -First 1

        if ($null -eq $arquivoEncontrado) {
            Write-Host "   -> AVISO: Sem arquivo do tipo '$tipoArquivo'." -ForegroundColor Yellow
        } 
        else {
            $nomeArquivoTipo = $tipoArquivo
            if ($tipoArquivo -eq "RG") { $nomeArquivoTipo = "RG1" }
            
            $partesNomePasta = $pasta.Name -split '_'
            $propostaCompleta = $partesNomePasta[0]
            $cpf = if ($partesNomePasta.Length -ge 2) { $partesNomePasta[1] } else { "CPF_NAO_IDENTIFICADO" }
            $extensao = $arquivoEncontrado.Extension
            $novoNome = "${cpf}_${nomeArquivoTipo}_${propostaCompleta}${extensao}"
            $caminhoDestinoFinal = Join-Path -Path (Join-Path -Path $caminhoDestinoRaiz -ChildPath $tipoArquivo) -ChildPath $novoNome
            Copy-Item -Path $arquivoEncontrado.FullName -Destination $caminhoDestinoFinal -Force
            Write-Host "   -> SUCESSO: Arquivo '$tipoArquivo' copiado como '$novoNome'." -ForegroundColor Cyan
        }
    }
}

Write-Host "----------------------------------------------------" -ForegroundColor Green
Write-Host "Processo conclu�do." -ForegroundColor Green
Write-Host ""
# --- LINHA AJUSTADA PARA GARANTIR A PAUSA ---
Read-Host -Prompt "O script terminou. Pressione Enter para fechar esta janela"
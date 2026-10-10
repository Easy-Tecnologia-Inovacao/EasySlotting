# Exclusão de planos pelo super admin

Implementado em 10/10/2026. Na tabela de planos, **Excluir** aparece ao lado de **Editar** e pede confirmação antes de enviar a solicitação. A tabela recorta seu conteúdo nos cantos arredondados. Durante a exclusão, outras ações de edição/criação/exclusão ficam bloqueadas para evitar solicitações sobrepostas.

Somente planos sem nenhuma assinatura vinculada podem ser excluídos. Assinaturas antigas, vencidas, canceladas ou pendentes também impedem a operação, mesmo que o plano esteja inativo. Para retirar uma oferta que já foi contratada, edite o plano e desative **Plano ativo**. Isso preserva contratos, histórico e benefícios vigentes.

## Contrato e integridade

- `DELETE /api/super_admin/plans/:id`: exige autenticação e role `super_admin` verificada no servidor.
- `204`: plano excluído; a interface remove a linha somente após essa resposta.
- `401/403`: credenciais ausentes/inadequadas ou usuário sem autorização.
- `404`: plano não encontrado, sem detalhes internos.
- `409`, código `PLAN_HAS_SUBSCRIPTIONS`: exclusão bloqueada; a interface preserva a linha e orienta a inativação.

O model já usa `restrict_with_exception`, e a chave estrangeira existente também impede a exclusão quando uma assinatura concorrente aparece após a consulta da associação. O controller trata ambas as recusas sem expor a exceção SQL. Uma transação própria/savepoint permite recuperar o conflito com o banco em estado utilizável. Não há exclusão em cascata nem nova migração.

Excluir um plano sem contratos retira sua oferta do catálogo. As regras de ordem crescente e limites de sessões continuam aplicadas às próximas criações/edições; excluir não muda os valores dos planos restantes.

A operação bem-sucedida solicita o registro `super_admin_delete_plan` com ator, IP, user agent e identificação do plano. O `AuditLogger` existente captura falhas de gravação: a auditoria não tem garantia de atomicidade com a exclusão. Para exigir esse requisito futuramente, será necessário alterar o contrato do logger e a transação.

## Revisão de segurança

Não foram identificadas novas vulnerabilidades confirmadas no escopo revisado. Isso não representa uma auditoria de toda a aplicação.

| Verificação | Evidência e resultado |
| --- | --- |
| Autorização e IDOR | `backend/app/controllers/super_admin/plans_controller.rb:3`: autorização precede a busca do plano. Testes negam acesso anônimo, owner, funcionário e cliente, inclusive com role/ID de administrador forjados no corpo. O catálogo é global e reservado ao super admin. |
| Integridade | `backend/app/controllers/super_admin/plans_controller.rb:60`: restrição do model e FK preservam contratos em todos os status. Teste reproduz associação em cache desatualizada e verifica o conflito da FK. |
| Entrada e interface | `frontend/src/views/super-admin/PlansPage/SuperAdminPlansPage.vue:645`: ID codificado na URL, confirmação e bloqueio de duplicação. Mensagens são renderizadas como texto Vue; falhas não removem a linha. |
| Segredos e privacidade | Alterações revisadas não incluem credenciais reais, arquivos de ambiente nem conteúdo de contratos. A auditoria segue os metadados já usados no sistema. |
| Uploads | Não aplicável: a operação não recebe arquivos. |

## Validação executada

- Backend: 28 testes, 230 assertions, sem falhas/erros, cobrindo exclusão, catálogo, ordenação e concorrência.
- Frontend: 28 testes aprovados, incluindo cancelamento, requisição pendente, conflito e nova tentativa.
- Build TypeScript/Vite aprovado; permanece o aviso de tamanho de chunk.
- Brakeman: zero alertas de segurança e zero erros de análise.
- Não houve exclusão de dados reais nem validação visual no navegador nesta execução.

import 'package:flutter/material.dart';

import 'package:animus/core/intake/dtos/second_instance_decision_dto.dart';
import 'package:animus/theme.dart';

class SecondInstanceDecisionCardView extends StatelessWidget {
  final SecondInstanceDecisionDto? decision;
  final bool isLoading;
  final VoidCallback? onPressed;

  const SecondInstanceDecisionCardView({
    this.decision,
    this.isLoading = false,
    this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.tokens;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool hasDecision =
        decision != null && decision!.description.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: tokens.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.borderSubtle),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Orientação da decisão',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        color: tokens.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      hasDecision
                          ? 'Revise ou ajuste a descrição antes de seguir para os próximos passos.'
                          : 'Descreva como a decisão deve ser orientada antes de avançar na análise.',
                      style: textTheme.bodySmall?.copyWith(
                        color: tokens.textMuted,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasDecision)
                IconButton(
                  onPressed: isLoading ? null : onPressed,
                  tooltip: 'Editar decisão',
                  icon: isLoading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: tokens.accent,
                          ),
                        )
                      : const Icon(Icons.edit_outlined, size: 18),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tokens.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: tokens.borderSubtle),
            ),
            child: hasDecision
                ? Text(
                    decision!.description.trim(),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: tokens.textSecondary,
                      height: 1.5,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Informe a orientação da decisão para contextualizar a minuta e o restante do fluxo desta análise.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: tokens.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: isLoading ? null : onPressed,
                          icon: isLoading
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: tokens.accent,
                                  ),
                                )
                              : const Icon(Icons.edit_note_outlined, size: 18),
                          label: const Text('Descrever decisão'),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

import { Injectable } from '@nestjs/common';
import { PrismaService } from 'nestjs-prisma';
import WagerStatus, { CreateWagerDto } from '../dtos/wager.dto';
import { Wager } from '@prisma/client';

@Injectable()
export class WagerService {
  constructor(private readonly prisma: PrismaService) {}

  async createWager(payload: CreateWagerDto) {
    return await this.prisma.wager.create({
      data: {
        ...payload,
        hashtags: {
          connect: payload.hashtags.map((name) => ({ name })),
        },
      },
    });
  }

  async getAllWagers(
    status: WagerStatus,
    hashtags?: string,
    filterType: 'AND' | 'OR' = 'OR',
    page?: number,
    limit?: number,
  ): Promise<{ data: Wager[]; total: number }> {
    const hashtagList = hashtags ? hashtags.split(',') : [];

    const query: any = {
      where: {
        status,
      },
      include: {
        hashtags: true,
      },
      skip: (page - 1) * limit,
      take: limit,
    };

    if (hashtagList.length > 0) {
      if (filterType === 'AND') {
        query.where.hashtags = {
          every: {
            name: {
              in: hashtagList,
            },
          },
        };
      } else {
        query.where.hashtags = {
          some: {
            name: {
              in: hashtagList,
            },
          },
        };
      }
    }

    const total = await this.prisma.wager.count({ where: query.where });

    const data = await this.prisma.wager.findMany(query);

    return { data, total };
  }

  async findOneById(id: string) {
    return await this.prisma.wager.findUnique({
      where: {
        id,
      },
    });
  }
}
